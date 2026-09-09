#!/usr/bin/env node
/**
 * 生成 plan 简洁流程预览 + 结构校验（构建 JSON 前必须运行，供用户确认）
 *
 * 用法:
 *   node scripts/preview-plan.mjs <plan.json>
 *   node scripts/preview-plan.mjs <plan.json> --json   # 额外输出 JSON 摘要
 */

import { readFileSync } from "node:fs";
import {
  detectPlanType,
  formatPlanPreview,
  normalizePlan,
  validatePlan,
} from "./lib/plan-summary.mjs";

function main() {
  const planPath = process.argv[2];
  const jsonOut = process.argv.includes("--json");

  if (!planPath) {
    console.error("usage: preview-plan.mjs <plan.json> [--json]");
    process.exit(2);
  }

  const raw = JSON.parse(readFileSync(planPath, "utf8"));
  const plan = normalizePlan(raw);
  const { warnings, errors, type } = validatePlan(plan);
  const preview = formatPlanPreview(plan);

  console.log("=== 流程预览（请确认后再构建 JSON）===");
  console.log("");
  console.log(preview);
  console.log("");

  if (warnings.length) {
    console.log("⚠️  结构警告（建议修正 plan 后再构建）：");
    for (const w of warnings) console.log(`  - ${w}`);
    console.log("");
  }

  if (errors.length) {
    console.log("❌ 错误（必须修正后才能构建）：");
    for (const e of errors) console.log(`  - ${e}`);
    console.log("");
  } else {
    console.log("✅ 指令 unionId 校验通过");
    console.log("");
    console.log("确认无误后执行构建：");
    if (type === "composite") {
      console.log(`  node scripts/build-composite-workflow.mjs ${planPath}`);
    } else {
      console.log(`  bash scripts/generate-workflow.sh --plan ${planPath}`);
    }
    console.log("");
  }

  if (jsonOut) {
    const stats = {
      type,
      preSteps: plan.preSteps?.length ?? 0,
      ifBranch: plan.ifElse?.ifBranch?.length ?? 0,
      elseBranch: plan.ifElse?.elseBranch?.length ?? 0,
      postSteps: plan.postSteps?.length ?? 0,
      instructionPlan: plan.instructionPlan?.length ?? 0,
    };
    console.log(JSON.stringify({ ok: errors.length === 0, warnings, errors, stats, preview }, null, 2));
  }

  process.exit(errors.length ? 1 : 0);
}

main();
