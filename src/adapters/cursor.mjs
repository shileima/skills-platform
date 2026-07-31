// Cursor adapter — plain skill folder (SKILL.md + supporting files).

import { skillsDir } from "../lib/ecosystems.mjs";
import { copyIncluded } from "../lib/fsutil.mjs";

export default {
  id: "cursor",
  skillsDir() {
    return skillsDir("cursor");
  },
  async stage(skill, srcDir, outDir) {
    await copyIncluded(skill.packInclude, srcDir, outDir);
  },
  async postInstall() {},
};
