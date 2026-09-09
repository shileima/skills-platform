#!/usr/bin/env node
/**
 * 组装完整编排 JSON（含 ifNode / elseNode 容器 + rpaNode）
 *
 * 用法: node scripts/build-composite-workflow.mjs <composite-plan.json> [output.json]
 *
 * 层级铁律（见 reference/composite-workflow.md）：
 * - 分支内只放「该分支独有」步骤
 * - 各分支（IF / Else / ElseIf）结束后都要执行的通用流程 → plan.postSteps，输出到 if/else 块**最外层之后**
 */

import { readFileSync, writeFileSync } from "node:fs";
import { buildNodesFromPlan } from "./lib/build-nodes.mjs";
import { fetchCommandList, resolveCommandMeta } from "./lib/fetch-commands.mjs";
import { generateId } from "./lib/generate-id.mjs";
import { expandPlanSteps } from "./lib/self-heal-scroll.mjs";

const PROBE_UNION_IDS = new Set([
  "WaitForElementPresent",
  "WaitForElementNotPresent",
  "VerifyElementPresent",
  "VerifyElementVisible",
]);

function buildLogicNode(type, tag, data, content = []) {
  return {
    type,
    attrs: {
      tag,
      icon: "",
      nodeId: generateId(),
      disabled: false,
      collapsed: false,
      breakpoints: false,
      nodeConfigState: "done",
      actionType: "",
      originalData: null,
      data,
    },
    content,
  };
}

/** 定位供 IF 引用的 preSteps 探测节点 */
export function findProbePreStepIndex(plan) {
  const pre = plan.preSteps || [];
  const byFlag = pre.findIndex((s) => s.params?.probeForIf);
  if (byFlag >= 0) return byFlag;
  if (plan.ifElse?.conditionPreStepIndex != null) return plan.ifElse.conditionPreStepIndex;
  return pre.findIndex((s) => PROBE_UNION_IDS.has(s.unionId));
}

/**
 * 探测结果保存到本节点（布尔型）：
 * - formData.outKey = ''（空，平台序列化后 outKey 属性 = nodeId）
 * - data.outKeyType = 'Boolean'（来自指令 API）
 * - IF 引用 ${nodeId}，禁止 ${nodeId}.xxx
 */
export async function bindProbeOutputToSelf(node) {
  const nodeId = node.attrs.nodeId;
  const unionId = node.attrs?.data?.unionId;
  node.attrs.data.formData.outKey = "";

  const list = await fetchCommandList();
  const { detail } = await resolveCommandMeta(unionId, list);
  const outKeyType = detail?.paramInfo?.xbotJson?.outKeyType;
  if (outKeyType) {
    node.attrs.data.outKeyType = outKeyType;
  }

  return nodeId;
}

async function buildIfElseBlock({ conditionLeft, ifPlan, elsePlan = [] }) {
  const ifBranch = await buildPlanSteps(ifPlan);
  const ifNode = buildLogicNode(
    "ifNode",
    "if",
    {
      title: "IF",
      logicalOperator: "and",
      conditions: [{ left: conditionLeft, comparisonOperator: "=", right: "true" }],
    },
    ifBranch,
  );
  const result = [ifNode];
  if (elsePlan.length) {
    const elseBranch = await buildPlanSteps(elsePlan);
    result.push(buildLogicNode("elseNode", "else", { title: "Else", logicalOperator: "and" }, elseBranch));
  }
  return result;
}

/** plan 步骤：普通 rpaNode 或内联 ifElse 块（见 reference/composite-workflow.md §内联分支） */
export function isIfElseBlock(step) {
  return step?.block === "ifElse" && step?.probeStep;
}

/**
 * 组装步骤列表（支持嵌套 ifElse）
 * - 普通步：{ unionId, params }
 * - 内联分支：{ block: "ifElse", probeStep, ifBranch?, elseBranch? }
 */
export async function buildPlanSteps(steps = []) {
  const nodes = [];
  for (const step of steps) {
    if (isIfElseBlock(step)) {
      const [probeNode] = await buildNodesFromPlan([step.probeStep]);
      const probeNodeId = await bindProbeOutputToSelf(probeNode);
      nodes.push(probeNode);
      nodes.push(
        ...(await buildIfElseBlock({
          conditionLeft: `\${${probeNodeId}}`,
          ifPlan: step.ifBranch || [],
          elsePlan: step.elseBranch || [],
        })),
      );
      continue;
    }
    nodes.push(...(await buildNodesFromPlan([step])));
  }
  return nodes;
}

async function main() {
  const planPath = process.argv[2];
  if (!planPath) {
    console.error("usage: build-composite-workflow.mjs <composite-plan.json> [output.json]");
    process.exit(2);
  }

  const planRaw = JSON.parse(readFileSync(planPath, "utf8"));
  const plan = {
    ...planRaw,
    preSteps: expandPlanSteps(planRaw.preSteps || []),
    ifElse: planRaw.ifElse
      ? {
          ...planRaw.ifElse,
          ifBranch: expandPlanSteps(planRaw.ifElse.ifBranch || []),
          elseBranch: expandPlanSteps(planRaw.ifElse.elseBranch || []),
        }
      : undefined,
    postSteps: expandPlanSteps(planRaw.postSteps || []),
  };
  const nodes = [];
  let probeNodeId = null;

  if (plan.preSteps?.length) {
    const preNodes = await buildNodesFromPlan(plan.preSteps);
    if (plan.ifElse) {
      const probeIdx = findProbePreStepIndex(plan);
      if (probeIdx >= 0) {
        probeNodeId = await bindProbeOutputToSelf(preNodes[probeIdx]);
      }
    }
    nodes.push(...preNodes);
  }

  if (plan.ifElse) {
    if (!probeNodeId) {
      throw new Error(
        "IF 需要 preSteps 中带 probeForIf 或 WaitForElementPresent 等探测节点",
      );
    }
    const conditionLeft = `\${${probeNodeId}}`;

    nodes.push(
      ...(await buildIfElseBlock({
        conditionLeft,
        ifPlan: plan.ifElse.ifBranch || [],
        elsePlan: plan.ifElse.elseBranch || [],
      })),
    );
  }

  // 通用流程：各分支结束后共享的步骤，放在 if/else 块之外（最外层）
  if (plan.postSteps?.length) {
    nodes.push(...(await buildPlanSteps(plan.postSteps)));
  }

  const outPath = process.argv[3] || planPath.replace(/\.json$/, ".nodes.json");
  validateCompositeVariableRefs(plan, nodes);
  writeFileSync(outPath, JSON.stringify(nodes, null, 2));
  console.log(JSON.stringify({ ok: true, count: nodes.length, output: outPath }));
}

/** 校验 IF 条件：探测节点 outKey 为空 + outKeyType Boolean；IF left === ${nodeId} */
function validateCompositeVariableRefs(plan, nodes) {
  if (!plan.ifElse) return;
  const probeIdx = findProbePreStepIndex(plan);
  const producer = probeIdx >= 0 ? nodes[probeIdx] : null;
  const nodeId = producer?.attrs?.nodeId;
  const outKey = producer?.attrs?.data?.formData?.outKey;
  const outKeyType = producer?.attrs?.data?.outKeyType;
  const errors = [];

  if (!nodeId) {
    errors.push("未找到 IF 探测 preSteps 节点");
  } else if (outKey !== "" && outKey != null) {
    const hint =
      outKey === nodeId
        ? "（禁止把 nodeId 字符串写入 outKey，会导致变量选择器出现 {nodeId}.xxx）"
        : "";
    errors.push(`探测节点 formData.outKey 必须为空（本节点），实际为 ${JSON.stringify(outKey)}${hint}`);
  }
  if (outKeyType && !/^boolean$/i.test(String(outKeyType))) {
    errors.push(`探测节点 outKeyType 应为 Boolean，实际为 ${outKeyType}`);
  }

  const ifNode = nodes.find((n) => n.type === "ifNode");
  const left = ifNode?.attrs?.data?.conditions?.[0]?.left ?? "";
  const expectedLeft = nodeId ? `\${${nodeId}}` : null;
  if (expectedLeft && left !== expectedLeft) {
    errors.push(`IF conditions.left 应为 ${expectedLeft}，实际为 ${left || "(空)"}`);
  }
  if (/^\$\{[^.]+\.[^}]+\}$/.test(left)) {
    errors.push(`IF 条件禁止使用 \${nodeId.field} 格式，探测结果应引用 \${nodeId}`);
  }

  if (errors.length) {
    throw new Error(`变量引用校验失败：\n- ${errors.join("\n- ")}`);
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
