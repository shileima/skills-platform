// Automan adapter — the richest target. On top of copying the skill files it
// generates .meta.json from skill.json, and supports packing to a zip and
// (opt-in) running declared dependency installers.

import { spawnSync } from "node:child_process";
import { join } from "node:path";
import { skillsDir } from "../lib/ecosystems.mjs";
import { copyIncluded, writeJson } from "../lib/fsutil.mjs";
import { automanMeta } from "../lib/skill.mjs";
import { warn, step, ok } from "../lib/log.mjs";

export default {
  id: "automan",
  skillsDir() {
    return skillsDir("automan");
  },

  async stage(skill, srcDir, outDir) {
    await copyIncluded(skill.packInclude, srcDir, outDir);
    // Generated metadata always overwrites any copied .meta.json.
    await writeJson(join(outDir, ".meta.json"), automanMeta(skill));
  },

  // Declared dependencies are NOT run by default (they are often `curl | bash`,
  // an outward-facing action). install --install-deps opts in.
  async postInstall(skill, destDir, opts = {}) {
    const deps = Array.isArray(skill.meta.dependencies) ? skill.meta.dependencies : [];
    if (deps.length === 0) return;

    if (!opts.installDeps) {
      warn(`${skill.name} declares ${deps.length} dependency(ies); not installed. Run with --install-deps to install:`);
      for (const d of deps) console.warn(`    ${d.name}: ${d.install}`);
      return;
    }

    for (const d of deps) {
      if (!d.install) continue;
      step(`installing dependency: ${d.name}`);
      if (opts.dryRun) {
        console.log(`    [dry-run] ${d.install}`);
        continue;
      }
      const r = spawnSync("bash", ["-c", d.install], { stdio: "inherit" });
      if (r.status !== 0) throw new Error(`dependency install failed: ${d.name}`);
      ok(`dependency installed: ${d.name}`);
    }
  },
};
