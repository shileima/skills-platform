// Central registry of supported ecosystems and their install locations.
// Paths are overridable via env vars so a wrong default is trivially fixed
// without touching adapter code.

import { homedir } from "node:os";
import { join } from "node:path";

const home = homedir();

export const ECOSYSTEMS = {
  cursor: {
    id: "cursor",
    label: "Cursor",
    defaultSkillsDir: join(home, ".cursor", "skills"),
    envVar: "SKILLDEV_CURSOR_SKILLS_DIR",
  },
  automan: {
    id: "automan",
    label: "Automan",
    defaultSkillsDir: join(home, ".automan", "claude-code-agents", "cua-agent", "skills"),
    envVar: "SKILLDEV_AUTOMAN_SKILLS_DIR",
  },
};

export const ECOSYSTEM_IDS = Object.keys(ECOSYSTEMS);

export function isEcosystem(id) {
  return Object.prototype.hasOwnProperty.call(ECOSYSTEMS, id);
}

// Resolve the install root for an ecosystem, honoring the env override.
export function skillsDir(id) {
  const eco = ECOSYSTEMS[id];
  if (!eco) throw new Error(`unknown ecosystem: ${id}`);
  const override = process.env[eco.envVar];
  return override && override.trim() ? override : eco.defaultSkillsDir;
}
