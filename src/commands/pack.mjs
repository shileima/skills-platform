// skilldev pack — build the automan distributable zip: dist/<name>_<version>.zip
// (name = automan registry name; may differ from the directory via metaName).

import { join } from "node:path";
import { promises as fs } from "node:fs";
import { loadSkill, automanName } from "../lib/skill.mjs";
import { stageSkill, distRoot } from "./build.mjs";
import { zipDir, hasZip } from "../lib/zip.mjs";
import { ok, step, info, warn, fail, c } from "../lib/log.mjs";

export default async function pack({ positionals, flags }) {
  const name = positionals[0];
  if (!name) fail("usage: skilldev pack <skill> [--dry-run]");

  const skill = await loadSkill(name);
  const anName = automanName(skill);
  const version = skill.meta.version;
  const zipName = `${anName}_${version}.zip`;
  const outZip = join(distRoot(), zipName);
  const staged = join(distRoot(), "automan", name);

  step(`packing ${c.bold(name)} → ${zipName}`);

  // Stage the automan payload (generates .meta.json).
  await stageSkill(skill, "automan", staged);

  const entries = (await fs.readdir(staged)).sort();
  info("  contents:");
  for (const e of entries) info(`    ${c.dim("+")} ${e}`);

  if (flags["dry-run"]) {
    warn(`dry-run: would write ${outZip}`);
    return;
  }
  if (!hasZip()) fail("`zip` not found in PATH");

  await zipDir(staged, outZip);
  ok(`wrote ${outZip}`);
}
