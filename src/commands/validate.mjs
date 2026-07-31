// skilldev validate — lint one or all skills. Non-zero exit on any error.

import { join } from "node:path";
import { listSkills, loadSkill } from "../lib/skill.mjs";
import { isValid as isSemver } from "../lib/semver.mjs";
import { ECOSYSTEM_IDS } from "../lib/ecosystems.mjs";
import { exists } from "../lib/fsutil.mjs";
import { ok, warn, info, fail, c } from "../lib/log.mjs";

const LINK_RE = /\]\(([^)]+)\)/g;

// Collect relative links from the SKILL.md body and verify they resolve.
async function checkLinks(skill) {
  const problems = [];
  let m;
  while ((m = LINK_RE.exec(skill.body)) !== null) {
    let target = m[1].trim();
    if (!target || /^(https?:|mailto:|#|\/\/)/.test(target)) continue;
    if (target.startsWith("/")) continue; // absolute paths: out of scope
    target = target.split("#")[0].split("?")[0]; // strip anchor / query
    if (!target) continue;
    const abs = join(skill.dir, target);
    if (!(await exists(abs))) problems.push(target);
  }
  return problems;
}

export async function validateSkill(name) {
  const errors = [];
  const warnings = [];
  let skill;
  try {
    skill = await loadSkill(name);
  } catch (e) {
    return { errors: [e.message], warnings };
  }

  const fm = skill.frontmatter || {};
  const meta = skill.meta || {};

  if (!fm.name) errors.push("SKILL.md frontmatter missing `name`");
  if (!fm.description) errors.push("SKILL.md frontmatter missing `description`");
  if (fm.name && fm.name !== name) errors.push(`SKILL.md name "${fm.name}" != directory "${name}"`);
  if (meta.name && meta.name !== name) errors.push(`skill.json name "${meta.name}" != directory "${name}"`);

  if (!isSemver(meta.version)) errors.push(`invalid version: ${JSON.stringify(meta.version)} (want x.y.z)`);

  const targets = meta.targets || [];
  if (!Array.isArray(targets) || targets.length === 0) {
    errors.push("skill.json `targets` must be a non-empty array");
  } else {
    for (const t of targets) {
      if (!ECOSYSTEM_IDS.includes(t)) errors.push(`unknown target: ${t} (known: ${ECOSYSTEM_IDS.join(", ")})`);
    }
  }

  if (meta.dependencies !== undefined) {
    if (!Array.isArray(meta.dependencies)) {
      errors.push("skill.json `dependencies` must be an array");
    } else {
      for (const d of meta.dependencies) {
        if (!d || !d.name || !d.install) warnings.push(`dependency missing name/install: ${JSON.stringify(d)}`);
      }
    }
  }

  const desc = fm.description || "";
  if (desc.length > 1024) warnings.push(`description is ${desc.length} chars (>1024 may be truncated by some runtimes)`);

  const brokenLinks = await checkLinks(skill);
  for (const l of brokenLinks) errors.push(`broken relative link in SKILL.md: ${l}`);

  return { errors, warnings };
}

export default async function validate({ positionals }) {
  const target = positionals[0];
  const names = target ? [target] : await listSkills();

  if (names.length === 0) {
    info("No skills to validate.");
    return;
  }

  let failed = 0;
  for (const name of names) {
    const { errors, warnings } = await validateSkill(name);
    for (const w of warnings) warn(`${c.bold(name)}: ${w}`);
    if (errors.length === 0) {
      ok(`${name}`);
    } else {
      failed++;
      for (const e of errors) console.error(`  ${c.red("✗")} ${c.bold(name)}: ${e}`);
    }
  }

  if (failed > 0) fail(`${failed} skill(s) failed validation`);
  info(`${c.green("All " + names.length + " skill(s) valid.")}`);
}
