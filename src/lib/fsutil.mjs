// Filesystem helpers shared by commands and adapters.

import { promises as fs } from "node:fs";
import { dirname, join } from "node:path";

export async function exists(p) {
  try {
    await fs.access(p);
    return true;
  } catch {
    return false;
  }
}

export async function ensureDir(p) {
  await fs.mkdir(p, { recursive: true });
}

export async function rmrf(p) {
  await fs.rm(p, { recursive: true, force: true });
}

// Recursively copy a file or directory (Node >=16.7 fs.cp).
export async function copyPath(src, dst) {
  await ensureDir(dirname(dst));
  await fs.cp(src, dst, { recursive: true });
}

// Force-create a symlink at linkPath pointing to target (replacing any existing).
export async function symlinkForce(target, linkPath) {
  await ensureDir(dirname(linkPath));
  await rmrf(linkPath);
  await fs.symlink(target, linkPath);
}

export async function readText(p) {
  return fs.readFile(p, "utf8");
}

export async function writeText(p, text) {
  await ensureDir(dirname(p));
  await fs.writeFile(p, text);
}

export async function writeJson(p, obj) {
  await writeText(p, JSON.stringify(obj, null, 2) + "\n");
}

export async function readJson(p) {
  return JSON.parse(await readText(p));
}

// Copy an allowlist of top-level entries (files or dirs) from srcDir to outDir.
// Missing entries are skipped silently. Returns the list of entries copied.
export async function copyIncluded(include, srcDir, outDir) {
  await ensureDir(outDir);
  const copied = [];
  for (const entry of include) {
    const from = join(srcDir, entry);
    if (await exists(from)) {
      await copyPath(from, join(outDir, entry));
      copied.push(entry);
    }
  }
  return copied;
}
