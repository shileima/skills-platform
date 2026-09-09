#!/usr/bin/env node
/** 元素不可见时，构建前插入「探测 + 逐步滚动再探测」自愈块（见 reference/self-heal-scroll.md） */

function isIfElseBlock(step) {
  return step?.block === "ifElse" && step?.probeStep;
}

/** 支持自愈展开的指令（含 selector） */
export const SELF_HEAL_ELEMENT_UNION_IDS = new Set([
  "ClickElementMixed",
  "FillText",
  "MouseOver",
  "ScrollToElement",
  "VerifyElementPresent",
  "VerifyElementVisible",
]);

/** 元素未出现时依次尝试的滚动偏移（相对滚动容器） */
export const DEFAULT_SCROLL_LADDER = [
  { x: "0", y: "300" },
  { x: "0", y: "600" },
  { x: "0", y: "900" },
  { x: "0", y: "0" },
  { x: "300", y: "0" },
  { x: "600", y: "0" },
];

function probeAliasFrom(selectorAlias) {
  if (/用于判断/.test(selectorAlias)) return selectorAlias;
  const base = selectorAlias.replace(/，用于.+$/, "");
  return `${base}，用于判断目标元素是否已在可视区域`;
}

function scrollContainerAlias(step, intentHint) {
  const custom = step.params?.selfHealScrollContainer?.alias;
  if (custom) return custom;
  if (/滚动区域|滚动容器|导航菜单/.test(step.params?.selector?.alias || "")) {
    return step.params.selector.alias.replace(/用于.+$/, "用于自愈滚动以寻找目标元素");
  }
  return `定位页面主内容滚动区域，用于自愈滚动以寻找${intentHint || "目标元素"}`;
}

function intentHint(selectorAlias = "") {
  const m = selectorAlias.match(/用于(.+?)$/);
  return m ? m[1].slice(0, 20) : "目标元素";
}

function makeProbeStep(selectorAlias, timeout) {
  return {
    unionId: "WaitForElementPresent",
    params: {
      timeout,
      failOptions: { failureHandling: "continue" },
      selector: { alias: probeAliasFrom(selectorAlias) },
    },
  };
}

function scrollStep({ x, y }, containerAlias) {
  return {
    unionId: "ScrollToPosition",
    params: {
      x: String(x),
      y: String(y),
      selector: { alias: containerAlias },
    },
  };
}

/**
 * Else 分支：每改一次偏移 → 滚动 → 再探测；已存在则 IF 空分支跳出，不再后续偏移。
 * 结构：Scroll → IF(可见)∅ Else [ Scroll → IF … ]
 */
export function buildChainedScrollElseBranch(ladder, probeStep, containerAlias) {
  if (!ladder.length) return [];

  const [head, ...tail] = ladder;
  const steps = [scrollStep(head, containerAlias)];

  steps.push({
    block: "ifElse",
    probeStep,
    ifBranch: [],
    elseBranch: tail.length ? buildChainedScrollElseBranch(tail, probeStep, containerAlias) : [],
  });

  return steps;
}

/**
 * 单步展开：selfHealScroll → [ ifElse(探测+链式滚动), 原步骤 ]
 * @returns {Array<object>}
 */
export function expandSelfHealScroll(step) {
  if (!step?.params?.selfHealScroll) return [step];
  if (!SELF_HEAL_ELEMENT_UNION_IDS.has(step.unionId)) return [step];
  const selector = step.params?.selector;
  if (!selector?.alias) return [step];

  const ladder = step.params.selfHealScrollLadder || DEFAULT_SCROLL_LADDER;
  const hint = intentHint(selector.alias);
  const containerAlias = scrollContainerAlias(step, hint);
  const timeout = String(step.params.selfHealProbeTimeout ?? "3000");
  const probeStep = makeProbeStep(selector.alias, timeout);

  const { selfHealScroll, selfHealScrollContainer, selfHealScrollLadder, selfHealProbeTimeout, ...restParams } =
    step.params;

  return [
    {
      block: "ifElse",
      probeStep,
      ifBranch: [],
      elseBranch: buildChainedScrollElseBranch(ladder, probeStep, containerAlias),
    },
    { ...step, params: restParams },
  ];
}

/** 递归展开 plan 步骤列表（含 postSteps 内联 ifElse 分支） */
export function expandPlanSteps(steps = []) {
  const out = [];
  for (const step of steps) {
    if (isIfElseBlock(step)) {
      out.push({
        ...step,
        ifBranch: expandPlanSteps(step.ifBranch || []),
        elseBranch: expandPlanSteps(step.elseBranch || []),
      });
      continue;
    }
    out.push(...expandSelfHealScroll(step));
  }
  return out;
}
