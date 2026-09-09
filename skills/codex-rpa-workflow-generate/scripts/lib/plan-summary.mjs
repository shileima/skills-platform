#!/usr/bin/env node
/** 从 plan JSON 生成简洁流程预览与结构校验 */

import { ALLOWED_UNION_IDS } from "./build-nodes.mjs";

const UNION_LABELS = {
  OpenUrl: "打开网页",
  NavigateToUrl: "导航到URL",
  FillText: "输入文本",
  ClickElementMixed: "点击元素",
  ReloadPage: "刷新网页",
  GetText: "获取文本",
  GetUrl: "获取URL",
  VerifyElementPresent: "验证元素存在",
  VerifyElementVisible: "验证元素可见",
  VerifyTextPresent: "验证文本存在",
  VerifyTextNotPresent: "验证文本不存在",
  WaitForElementPresent: "等待元素存在",
  WaitForElementNotPresent: "等待元素不存在",
  WaitPageState: "等待页面加载",
  TakeScreenshot: "截图",
  SendKeys: "模拟键盘",
  ScrollToElement: "滚动到元素",
  ScrollToPosition: "滚动",
  MouseOver: "鼠标悬停",
  BackPage: "后退",
  ForwardPage: "前进",
  Delay: "延迟",
};

const SCROLL_UNION_IDS = new Set(["ScrollToPosition", "ScrollToElement"]);

export function isIfElseBlock(step) {
  return step?.block === "ifElse" && step?.probeStep;
}

/** 展开 postSteps 中的内联 ifElse，供校验与计数 */
export function flattenPlanSteps(steps = []) {
  const out = [];
  for (const step of steps) {
    if (isIfElseBlock(step)) {
      out.push(step.probeStep);
      out.push(...flattenPlanSteps(step.ifBranch || []));
      out.push(...flattenPlanSteps(step.elseBranch || []));
    } else {
      out.push(step);
    }
  }
  return out;
}

function inlineIfElseSummary(step) {
  const probe = step.probeStep;
  const alias = probe?.params?.selector?.alias || "";
  let label = "探测=true";
  if (/添加商品/.test(alias)) label = "添加商品按钮已出现";
  const elseSteps = step.elseBranch || [];
  const elsePart =
    elseSteps.length > 0
      ? `；否则 ${summarizeSteps(elseSteps).join(" → ")}`
      : "";
  return `IF（${label}）${elsePart}`;
}

function stepDetail(step) {
  const p = step.params || {};
  if (step.unionId === "OpenUrl" || step.unionId === "NavigateToUrl") {
    const url = p.url || p.rawUrl || "";
    try {
      return new URL(url).hostname || url.slice(0, 40);
    } catch {
      return url.slice(0, 40);
    }
  }
  if (step.unionId === "FillText") return p.text ? `"${String(p.text).slice(0, 20)}"` : "";
  if (step.unionId === "VerifyTextPresent" || step.unionId === "VerifyTextNotPresent") {
    return p.text ? `"${p.text}"` : "";
  }
  if (step.unionId === "ScrollToPosition") {
    const y = p.y ?? p.scrollY ?? "";
    return y ? `${y}px` : "";
  }
  if (p.selfHealScroll) return "→ 滚动自愈";
  if (step.unionId === "WaitForElementPresent" && p.probeForIf) return "→ 本节点(IF探测)";
  if (step.unionId === "WaitForElementPresent" && p.outKey) return `→ ${p.outKey}`;
  if (p.selector?.alias) {
    const a = p.selector.alias;
    const m = a.match(/用于(.+?)$/);
    return m ? m[1].slice(0, 24) : a.slice(0, 24);
  }
  return "";
}

export function stepSummary(step) {
  if (isIfElseBlock(step)) return inlineIfElseSummary(step);
  const label = UNION_LABELS[step.unionId] || step.unionId;
  const detail = stepDetail(step);
  return detail ? `${label}（${detail}）` : label;
}

export function summarizeSteps(steps = []) {
  return steps.map(stepSummary);
}

function stepsSignature(steps = []) {
  return steps.map((s) => s.unionId).join(",");
}

function tailOverlap(a = [], b = []) {
  if (!a.length || !b.length) return 0;
  const max = Math.min(a.length, b.length);
  for (let len = max; len >= 2; len--) {
    const tailA = a.slice(-len).map((s) => s.unionId).join(",");
    const tailB = b.slice(0, len).map((s) => s.unionId).join(",");
    if (tailA === tailB) return len;
  }
  return 0;
}

function branchOverlapWithPost(branch = [], post = []) {
  if (!branch.length || !post.length) return 0;
  return tailOverlap(branch, post);
}

export function detectPlanType(plan) {
  if (plan.ifElse || plan.preSteps) return "composite";
  if (plan.instructionPlan) return "linear";
  if (Array.isArray(plan)) return "linear";
  return "unknown";
}

export function normalizePlan(plan) {
  if (Array.isArray(plan)) {
    return { workflowName: "未命名", instructionPlan: plan };
  }
  return plan;
}

export function collectAllSteps(plan) {
  const type = detectPlanType(plan);
  if (type === "linear") {
    return plan.instructionPlan || [];
  }
  return [
    ...(plan.preSteps || []),
    ...(plan.ifElse?.ifBranch || []),
    ...(plan.ifElse?.elseBranch || []),
    ...flattenPlanSteps(plan.postSteps || []),
  ];
}

export function validatePlan(plan) {
  const warnings = [];
  const errors = [];
  const type = detectPlanType(plan);

  for (const step of collectAllSteps(plan)) {
    if (!ALLOWED_UNION_IDS.has(step.unionId)) {
      errors.push(`不支持的指令 unionId=${step.unionId}`);
    }
  }

  if (type !== "composite") {
    return { warnings, errors, type };
  }

  const ifBranch = plan.ifElse?.ifBranch || [];
  const elseBranch = plan.ifElse?.elseBranch || [];
  const postSteps = plan.postSteps || [];

  const ifOverlap = branchOverlapWithPost(ifBranch, postSteps);
  const elseOverlap = branchOverlapWithPost(elseBranch, postSteps);
  if (ifOverlap >= 2) {
    warnings.push(
      `ifBranch 末尾与 postSteps 前 ${ifOverlap} 步重复，通用流程应只写在 postSteps`,
    );
  }
  if (elseOverlap >= 2) {
    warnings.push(
      `elseBranch 末尾与 postSteps 前 ${elseOverlap} 步重复，通用流程应只写在 postSteps`,
    );
  }

  if (ifBranch.length > 0 && postSteps.length === 0 && elseBranch.length > 5) {
    warnings.push("elseBranch 步骤较多但 postSteps 为空，确认通用流程是否误写在分支内");
  }

  function scrollKey(step) {
    if (!SCROLL_UNION_IDS.has(step.unionId)) return null;
    const p = step.params || {};
    return `${step.unionId}|y:${p.y ?? p.scrollY ?? ""}|${(p.selector?.alias || "").slice(0, 40)}`;
  }

  const postScrollKeys = new Set(postSteps.map(scrollKey).filter(Boolean));
  for (const [name, branch] of [
    ["ifBranch", ifBranch],
    ["elseBranch", elseBranch],
  ]) {
    for (const s of branch) {
      const k = scrollKey(s);
      if (k && postScrollKeys.has(k)) {
        warnings.push(`${name} 与 postSteps 含相同滚动步骤，应只保留在 postSteps（通用流程）`);
      }
    }
  }

  const ifScrollKeys = ifBranch.map(scrollKey).filter(Boolean);
  const elseScrollKeys = elseBranch.map(scrollKey).filter(Boolean);
  for (const k of ifScrollKeys) {
    if (elseScrollKeys.includes(k)) {
      warnings.push("相同滚动步骤同时出现在 IF 与 Else，汇合后都要滚动的应移入 postSteps");
    }
  }

  if (elseScrollKeys.length && !ifScrollKeys.length && postSteps.length > 0) {
    warnings.push(
      "滚动仅在 elseBranch：若 IF 路径登录后汇合时也需要同样滚动，应移入 postSteps；若仅无登录框时才滚侧栏则正确",
    );
  }

  if (postSteps.length > 0) {
    const postSig = stepsSignature(postSteps);
    const ifSig = stepsSignature(ifBranch);
    const elseSig = stepsSignature(elseBranch);
    if (ifSig.endsWith(postSig) || elseSig.endsWith(postSig)) {
      warnings.push("检测到分支内完整包含 postSteps 序列，请提取到 postSteps 最外层");
    }
  }

  return { warnings, errors, type };
}

function formatStepList(steps, { maxShow = 4 } = {}) {
  if (!steps.length) return "（空）";
  const labels = summarizeSteps(steps);
  if (labels.length <= maxShow) return labels.join(" → ");
  const head = labels.slice(0, 2).join(" → ");
  const tail = labels.slice(-1)[0];
  return `${head} → …（共 ${labels.length} 步）→ ${tail}`;
}

function conditionLabel(plan) {
  const pre = plan.preSteps || [];
  const probe =
    pre.find((s) => s.params?.probeForIf) ||
    (plan.ifElse?.conditionPreStepIndex != null ? pre[plan.ifElse.conditionPreStepIndex] : null) ||
    pre.find((s) => s.unionId === "WaitForElementPresent");
  if (probe?.unionId === "WaitForElementPresent") {
    const alias = probe.params?.selector?.alias || "";
    if (/登录|账号|密码/.test(alias)) return "有登录框";
  }
  return "探测=true";
}

function elseConditionLabel(plan) {
  const label = conditionLabel(plan);
  if (label === "有登录框") return "无登录框";
  return `非（${label}）`;
}

export function formatCompositePreview(plan) {
  const lines = [];
  const name = plan.workflowName || "未命名工作流";
  const pre = plan.preSteps || [];
  const ifBranch = plan.ifElse?.ifBranch || [];
  const elseBranch = plan.ifElse?.elseBranch || [];
  const postSteps = plan.postSteps || [];
  const postCount = postSteps.length;

  lines.push(`工作流：${name}`);
  if (plan.targetUrl) lines.push(`目标 URL：${plan.targetUrl}`);
  lines.push("");

  if (pre.length) {
    lines.push(formatStepList(pre));
  }

  if (plan.ifElse) {
    const ifLabel = conditionLabel(plan);
    const elseLabel = elseConditionLabel(plan);

    if (ifBranch.length && elseBranch.length) {
      const ifOnly = formatStepList(ifBranch);
      const elseOnly = formatStepList(elseBranch);
      if (postCount) {
        lines.push(`├─ IF（${ifLabel}）：${ifOnly} → 通用流程（${postCount} 步）`);
        lines.push(`└─ Else（${elseLabel}）：${elseOnly} → 通用流程（${postCount} 步）`);
      } else {
        lines.push(`├─ IF（${ifLabel}）：${ifOnly}`);
        lines.push(`└─ Else（${elseLabel}）：${elseOnly}`);
      }
    } else if (ifBranch.length) {
      const ifOnly = formatStepList(ifBranch);
      if (postCount) {
        lines.push(`IF（${ifLabel}）：${ifOnly}`);
        lines.push(`→ 通用流程（${postCount} 步，无登录框时跳过 IF 直接执行）`);
      } else {
        lines.push(`IF（${ifLabel}）：${ifOnly}`);
      }
    } else if (elseBranch.length) {
      const elseOnly = formatStepList(elseBranch);
      if (postCount) {
        lines.push(`Else（${elseLabel}）：${elseOnly} → 通用流程（${postCount} 步）`);
      } else {
        lines.push(`Else（${elseLabel}）：${elseOnly}`);
      }
    }

    if (postCount) {
      lines.push("");
      lines.push(`通用流程（postSteps，${postCount} 步）：`);
      lines.push(formatStepList(postSteps, { maxShow: 6 }));
    }
  }

  return lines.join("\n");
}

export function formatLinearPreview(plan) {
  const steps = plan.instructionPlan || [];
  const lines = [];
  lines.push(`工作流：${plan.workflowName || "未命名工作流"}`);
  if (plan.targetUrl) lines.push(`目标 URL：${plan.targetUrl}`);
  lines.push("");
  lines.push(formatStepList(steps, { maxShow: 8 }));
  lines.push("");
  lines.push(`共 ${steps.length} 步（线性，无分支）`);
  return lines.join("\n");
}

export function formatPlanPreview(plan) {
  const normalized = normalizePlan(plan);
  const type = detectPlanType(normalized);
  if (type === "composite") return formatCompositePreview(normalized);
  if (type === "linear") return formatLinearPreview(normalized);
  return "无法识别 plan 结构（需 instructionPlan 或 preSteps+ifElse）";
}
