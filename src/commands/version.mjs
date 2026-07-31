// skilldev version <skill> <major|minor|patch|x.y.z> — bump a skill's version
// in skill.json and prepend a CHANGELOG stub if one exists.

import { join } from "node:path";
import { loadSkill } from "../lib/skill.mjs";
import { bump } from "../lib/semver.mjs";
import { readJson, writeJson, exists, readText, writeText } from "../lib/fsutil.mjs";
import { ok, info, fail, c } from "../lib/log.mjs";

async function prependChangelog(dir, version) {
  const path = join(dir, "CHANGELOG.md");
  if (!(await exists(path))) return false;
  const text = await readText(path);
  const entry = `## [${version}] - unreleased\n\n### Changed\n- \n\n`;
  const lines = text.split("\n");
  // Insert after the first top-level heading (# ...) if present, else at top.
  let idx = lines.findIndex((l) => l.startsWith("# "));
  if (idx === -1) {
    await writeText(path, entry + text);
  } else {
    // skip a blank line following the heading
    let insertAt = idx + 1;
    while (insertAt < lines.length && lines[insertAt].trim() === "") insertAt++;
    lines.splice(insertAt, 0, "", ...entry.trimEnd().split("\n"), "");
    await writeText(path, lines.join("\n"));
  }
  return true;
}

export default async function version({ positionals }) {
  const name = positionals[0];
  const kind = positionals[1];
  if (!name || !kind) fail("usage: skilldev version <skill> <major|minor|patch|x.y.z>");

  const skill = await loadSkill(name);
  const current = skill.meta.version;
  const next = bump(current, kind);

  const metaPath = join(skill.dir, "skill.json");
  const meta = await readJson(metaPath);
  meta.version = next;
  await writeJson(metaPath, meta);
  ok(`${name}: ${current} → ${c.bold(next)}`);

  const wrote = await prependChangelog(skill.dir, next);
  if (wrote) info(`  updated ${name}/CHANGELOG.md (fill in the entry)`);
}
