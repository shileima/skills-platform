#!/usr/bin/env node
/**
 * 组装完整编排 JSON（含 ifNode/elseNode 容器 + rpaNode 子节点）
 * 用法: node scripts/build-composite-workflow.mjs <plan.json> [output.json]
 */

import { readFileSync, writeFileSync } from "node:fs";
import { buildNodesFromPlan } from "./lib/build-nodes.mjs";
import { generateId } from "./lib/generate-id.mjs";

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

async function buildIfElseBlock({ conditionLeft, ifPlan, elsePlan = [] }) {
  const ifBranch = await buildNodesFromPlan(ifPlan);
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
    const elseBranch = await buildNodesFromPlan(elsePlan);
    result.push(buildLogicNode("elseNode", "else", { title: "Else", logicalOperator: "and" }, elseBranch));
  }
  return result;
}

async function main() {
  const planPath = process.argv[2];
  const outPath = process.argv[3] || planPath.replace(/\.json$/, ".nodes.json");
  if (!planPath) {
    console.error("usage: build-composite-workflow.mjs <composite-plan.json> [output.json]");
    process.exit(2);
  }

  const plan = JSON.parse(readFileSync(planPath, "utf8"));
  const nodes = [];

  if (plan.preSteps?.length) {
    nodes.push(...(await buildNodesFromPlan(plan.preSteps)));
  }

  if (plan.ifElse) {
    const verifyNode = nodes.find((n) => n.attrs?.data?.formData?.outKey);
    const outKey = plan.ifElse.conditionVar || verifyNode?.attrs?.data?.formData?.outKey || "hasLoginForm";
    const verifyNodeId = verifyNode?.attrs?.nodeId;
    const conditionLeft = verifyNodeId ? `\${${verifyNodeId}.${outKey}}` : `\${${outKey}}`;
    nodes.push(
      ...(await buildIfElseBlock({
        conditionLeft,
        ifPlan: plan.ifElse.ifBranch,
        elsePlan: plan.ifElse.elseBranch || [],
      })),
    );
  }

  if (plan.postSteps?.length) {
    nodes.push(...(await buildNodesFromPlan(plan.postSteps)));
  }

  writeFileSync(outPath, JSON.stringify(nodes, null, 2));
  console.log(JSON.stringify({ ok: true, count: nodes.length, output: outPath }));
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
