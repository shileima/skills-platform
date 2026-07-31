// Codex adapter — plain skill folder. Optionally mirrors into the cross-runtime
// alias ~/.agents/skills when SKILLDEV_CODEX_MIRROR_AGENTS is set.

import { skillsDir, mirrorDir } from "../lib/ecosystems.mjs";
import { copyIncluded } from "../lib/fsutil.mjs";

export default {
  id: "codex",
  skillsDir() {
    return skillsDir("codex");
  },
  // Additional install roots (e.g. the ~/.agents/skills alias). [] when off.
  extraSkillsDirs() {
    const m = mirrorDir("codex");
    return m ? [m] : [];
  },
  async stage(skill, srcDir, outDir) {
    await copyIncluded(skill.packInclude, srcDir, outDir);
  },
  async postInstall() {},
};
