// Zip helper — shells out to the system `zip` (present on macOS/Linux).
// Archives the *contents* of stageDir at the archive root (matching the
// automan skill packaging convention: .meta.json / SKILL.md / ... at top level).

import { spawnSync } from "node:child_process";
import { dirname } from "node:path";
import { ensureDir, rmrf } from "./fsutil.mjs";

export function hasZip() {
  const r = spawnSync("zip", ["-v"], { stdio: "ignore" });
  return r.status === 0;
}

export async function zipDir(stageDir, outZipPath) {
  if (!hasZip()) {
    throw new Error("`zip` not found in PATH — install it (macOS/Linux ship it) or set PATH");
  }
  await ensureDir(dirname(outZipPath));
  await rmrf(outZipPath);
  // -r recurse, -q quiet, -X strip extra file attributes for reproducibility.
  // "." zips everything under stageDir at the archive root.
  const r = spawnSync("zip", ["-r", "-q", "-X", outZipPath, "."], {
    cwd: stageDir,
    stdio: "inherit",
  });
  if (r.status !== 0) {
    throw new Error(`zip failed with exit code ${r.status}`);
  }
  return outZipPath;
}
