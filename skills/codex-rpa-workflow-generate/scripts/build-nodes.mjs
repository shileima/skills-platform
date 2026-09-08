#!/usr/bin/env node
import { buildNodesFromPlan } from "./lib/build-nodes.mjs";
import { readFileSync, writeFileSync } from "node:fs";

const planPath = process.argv[2];
const outPath = process.argv[3];
if (!planPath) {
  console.error("usage: build-nodes.mjs <instruction-plan.json> [output.json]");
  process.exit(2);
}
const plan = JSON.parse(readFileSync(planPath, "utf8"));
const steps = plan.instructionPlan || plan;
const nodes = await buildNodesFromPlan(steps);
const output = outPath || planPath.replace(/\.json$/, ".nodes.json");
writeFileSync(output, JSON.stringify(nodes, null, 2));
console.log(JSON.stringify({ ok: true, count: nodes.length, output }));
