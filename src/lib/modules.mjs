// Shared skill modules — staged into each skill package at build/install time.

import { promises as fs } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { copyPath, exists } from "./fsutil.mjs";

const __dirname = dirname(fileURLToPath(import.meta.url));

export function modulesRoot() {
  return join(__dirname, "..", "modules");
}

export function moduleDir(name) {
  return join(modulesRoot(), name);
}

export async function listModules() {
  const root = modulesRoot();
  if (!(await exists(root))) return [];
  const entries = await fs.readdir(root, { withFileTypes: true });
  const names = [];
  for (const e of entries) {
    if (!e.isDirectory()) continue;
    const dir = join(root, e.name);
    if ((await exists(join(dir, "MODULE.md"))) || (await exists(join(dir, "scripts")))) {
      names.push(e.name);
    }
  }
  return names.sort();
}

export async function stageModules(skill, outDir) {
  const modules = skill.meta.modules || [];
  if (!Array.isArray(modules) || modules.length === 0) return [];

  const staged = [];
  for (const name of modules) {
    const src = moduleDir(name);
    if (!(await exists(src))) {
      throw new Error(`${skill.name}: module not found: ${name} (${src})`);
    }
    const dest = join(outDir, "modules", name);
    await copyPath(src, dest);
    staged.push(name);
  }
  return staged;
}

export async function validateModules(skill) {
  const errors = [];
  const modules = skill.meta.modules;
  if (modules === undefined) return errors;
  if (!Array.isArray(modules)) {
    errors.push("skill.json `modules` must be an array");
    return errors;
  }
  for (const name of modules) {
    if (typeof name !== "string" || !name) {
      errors.push(`invalid module name: ${JSON.stringify(name)}`);
      continue;
    }
    const dir = moduleDir(name);
    if (!(await exists(dir))) errors.push(`module not found: ${name}`);
    else if (!(await exists(join(dir, "MODULE.md"))) && !(await exists(join(dir, "scripts")))) {
      errors.push(`module ${name} missing MODULE.md or scripts/`);
    }
  }
  return errors;
}
