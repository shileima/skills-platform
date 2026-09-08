#!/usr/bin/env node
/** 校验 build-nodes 产物中已知会导致引擎报错的 formData 结构 */

import { readFileSync } from "node:fs";
import { buildNodesFromPlan } from "./lib/build-nodes.mjs";

/** unionId → 禁止出现在 formData 顶层的 key（经调试确认） */
const FORBIDDEN_TOP_LEVEL = {
  WaitPageState: ["timeout"],
  NavigateToUrl: ["url"],
  SendKeys: ["sendKeys"],
  Delay: ["delay", "ms"],
};

/** unionId → 必须存在的 key */
const REQUIRED_KEYS = {
  WaitPageState: ["loadState", "waitForLoadStateOptions"],
  NavigateToUrl: ["rawUrl"],
  OpenUrl: ["navigateOptions"],
  SendKeys: ["keys"],
  TakeScreenshot: ["screenshotOption", "outKey"],
};

async function main() {
  const planPath = process.argv[2];
  if (!planPath) {
    console.error("usage: validate-built-nodes.mjs <instruction-plan.json>");
    process.exit(2);
  }
  const plan = JSON.parse(readFileSync(planPath, "utf8"));
  const steps = plan.instructionPlan || plan;
  const nodes = await buildNodesFromPlan(steps);
  const errors = [];

  for (const node of nodes) {
    const unionId = node.attrs?.data?.unionId;
    const formData = node.attrs?.data?.formData ?? {};

    for (const key of FORBIDDEN_TOP_LEVEL[unionId] ?? []) {
      if (key in formData) {
        errors.push({ unionId, key, reason: "forbidden top-level attribute" });
      }
    }

    for (const key of REQUIRED_KEYS[unionId] ?? []) {
      if (!(key in formData)) {
        errors.push({ unionId, key, reason: "missing required key" });
      }
    }

    if (unionId === "WaitPageState" && formData.waitForLoadStateOptions) {
      if (!("timeout" in formData.waitForLoadStateOptions)) {
        errors.push({ unionId, key: "waitForLoadStateOptions.timeout", reason: "missing nested timeout" });
      }
    }

    if (unionId === "OpenUrl" && formData.navigateOptions) {
      if (!("timeout" in formData.navigateOptions)) {
        errors.push({ unionId, key: "navigateOptions.timeout", reason: "missing navigation timeout" });
      }
    }
  }

  if (errors.length) {
    console.error(JSON.stringify({ ok: false, errors }, null, 2));
    process.exit(1);
  }
  console.log(JSON.stringify({ ok: true, count: nodes.length }));
}

main().catch((e) => {
  console.error(JSON.stringify({ ok: false, error: e.message }));
  process.exit(1);
});
