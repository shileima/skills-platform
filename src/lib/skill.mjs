// Skill discovery + loading. A skill lives in skills/<name>/ with a SKILL.md
// (name/description frontmatter) and a skill.json (metadata superset).

import { promises as fs } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join, resolve } from "node:path";
import { parseFrontmatter } from "./frontmatter.mjs";
import { exists, readText, readJson } from "./fsutil.mjs";

const __dirname = dirname(fileURLToPath(import.meta.url));

export function repoRoot() {
  // src/lib/skill.mjs → repo root is two directories up.
  return resolve(__dirname, "..", "..");
}

export function skillsRoot() {
  return join(repoRoot(), "skills");
}

export function skillDir(name) {
  return join(skillsRoot(), name);
}

export const DEFAULT_PACK_INCLUDE = [
  ".meta.json",
  "SKILL.md",
  "README.md",
  "CHANGELOG.md",
  "reference",
  "scripts",
  "assets",
];

// List skill directory names (folders under skills/ containing a skill.json).
export async function listSkills() {
  const root = skillsRoot();
  if (!(await exists(root))) return [];
  const entries = await fs.readdir(root, { withFileTypes: true });
  const names = [];
  for (const e of entries) {
    if (!e.isDirectory()) continue;
    if (await exists(join(root, e.name, "skill.json"))) names.push(e.name);
  }
  return names.sort();
}

// Load a skill by name. Throws if it or its required files are missing.
export async function loadSkill(name) {
  const dir = skillDir(name);
  const metaPath = join(dir, "skill.json");
  const skillMdPath = join(dir, "SKILL.md");
  if (!(await exists(dir))) throw new Error(`skill not found: ${name} (${dir})`);
  if (!(await exists(metaPath))) throw new Error(`missing skill.json in ${name}`);
  if (!(await exists(skillMdPath))) throw new Error(`missing SKILL.md in ${name}`);

  const meta = await readJson(metaPath);
  const { data: frontmatter, body } = await parseFrontmatter(await readText(skillMdPath));

  return {
    name,
    dir,
    meta,
    frontmatter,
    body,
    packInclude: (meta.pack && meta.pack.include) || DEFAULT_PACK_INCLUDE,
  };
}

// The name automan should register this skill under (may differ from dir name).
export function automanName(skill) {
  return (skill.meta.automan && skill.meta.automan.metaName) || skill.name;
}

// Build the automan .meta.json object from skill.json.
export function automanMeta(skill) {
  const m = skill.meta;
  return {
    name: automanName(skill),
    author: m.author || "",
    description: m.description || "",
    version: m.version,
    source: (m.automan && m.automan.source) || "user",
    dependencies: Array.isArray(m.dependencies) ? m.dependencies : [],
  };
}
