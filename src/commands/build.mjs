// skilldev build — stage skills into dist/<target>/<name>/ per ecosystem.

import { join } from "node:path";
import { listSkills, loadSkill, repoRoot } from "../lib/skill.mjs";
import { ECOSYSTEM_IDS } from "../lib/ecosystems.mjs";
import { getAdapter } from "../adapters/index.mjs";
import { rmrf } from "../lib/fsutil.mjs";
import { ok, step, info, fail, c } from "../lib/log.mjs";

export function distRoot() {
  return join(repoRoot(), "dist");
}

// Resolve which ecosystem ids to build for a skill given the --target flag.
export function resolveTargets(skill, flags) {
  const declared = skill.meta.targets || [];
  if (!flags.target || flags.target === true || flags.target === "all") {
    if (declared.length === 0) fail(`${skill.name}: no targets declared and none given`);
    return declared;
  }
  const ids = String(flags.target)
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);
  for (const id of ids) {
    if (!ECOSYSTEM_IDS.includes(id)) fail(`unknown target: ${id} (known: ${ECOSYSTEM_IDS.join(", ")})`);
  }
  return ids;
}

// Stage one skill for one ecosystem into outDir (cleaned first). Returns outDir.
export async function stageSkill(skill, targetId, outDir) {
  const adapter = getAdapter(targetId);
  await rmrf(outDir);
  await adapter.stage(skill, skill.dir, outDir);
  return outDir;
}

export default async function build({ positionals, flags }) {
  const only = positionals[0];
  const names = only ? [only] : await listSkills();
  if (names.length === 0) fail("no skills to build");

  for (const name of names) {
    const skill = await loadSkill(name);
    const targets = resolveTargets(skill, flags);
    step(`building ${c.bold(name)} → ${targets.join(", ")}`);
    for (const t of targets) {
      const outDir = join(distRoot(), t, name);
      await stageSkill(skill, t, outDir);
      ok(`${t}: ${outDir}`);
    }
  }
  info(c.green("Build complete."));
}
