// skilldev new <name> — scaffold skills/<name>/ from templates/skill/.

import { spawnSync } from "node:child_process";
import { promises as fs } from "node:fs";
import { join } from "node:path";
import { repoRoot, skillDir } from "../lib/skill.mjs";
import { exists, copyPath, readText, writeText } from "../lib/fsutil.mjs";
import { ok, info, fail, c } from "../lib/log.mjs";

const NAME_RE = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;

function detectAuthor() {
  const r = spawnSync("git", ["config", "user.name"], { encoding: "utf8" });
  const n = r.status === 0 ? r.stdout.trim() : "";
  return n || "you";
}

async function walk(dir) {
  const out = [];
  for (const e of await fs.readdir(dir, { withFileTypes: true })) {
    const p = join(dir, e.name);
    if (e.isDirectory()) out.push(...(await walk(p)));
    else out.push(p);
  }
  return out;
}

export default async function newSkill({ positionals, flags }) {
  const name = positionals[0];
  if (!name) fail("usage: skilldev new <name> [--author <name>]");
  if (!NAME_RE.test(name)) fail(`invalid skill name "${name}" — use lowercase-kebab-case`);

  const dest = skillDir(name);
  if ((await exists(dest)) && !flags.force) fail(`skill already exists: ${dest} (use --force to overwrite)`);

  const template = join(repoRoot(), "templates", "skill");
  await copyPath(template, dest);

  const author = flags.author && flags.author !== true ? String(flags.author) : detectAuthor();
  for (const file of await walk(dest)) {
    if (!/\.(md|json)$/.test(file)) continue;
    const text = await readText(file);
    const replaced = text.replace(/__NAME__/g, name).replace(/__AUTHOR__/g, author);
    if (replaced !== text) await writeText(file, replaced);
  }

  ok(`created ${c.bold("skills/" + name + "/")}`);
  info("Next:");
  info(`  1. edit skills/${name}/SKILL.md and skill.json`);
  info(`  2. skilldev validate ${name}`);
  info(`  3. skilldev install ${name} --target claude --dry-run`);
}
