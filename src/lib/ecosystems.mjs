// Central registry of supported ecosystems and their install locations.
// Paths are overridable via env vars so a wrong default is trivially fixed
// without touching adapter code.

import { homedir } from "node:os";
import { join } from "node:path";

const home = homedir();

export const ECOSYSTEMS = {
  claude: {
    id: "claude",
    label: "Claude Code",
    defaultSkillsDir: join(home, ".claude", "skills"),
    envVar: "SKILLDEV_CLAUDE_SKILLS_DIR",
  },
  codex: {
    id: "codex",
    label: "Codex",
    defaultSkillsDir: join(home, ".codex", "skills"),
    envVar: "SKILLDEV_CODEX_SKILLS_DIR",
    // Optional cross-runtime alias mirror (~/.agents/skills). Off by default;
    // enable with SKILLDEV_CODEX_MIRROR_AGENTS=1.
    mirror: {
      envVar: "SKILLDEV_CODEX_MIRROR_AGENTS",
      dir: join(home, ".agents", "skills"),
    },
  },
  cursor: {
    id: "cursor",
    label: "Cursor",
    defaultSkillsDir: join(home, ".cursor", "skills"),
    envVar: "SKILLDEV_CURSOR_SKILLS_DIR",
  },
  automan: {
    id: "automan",
    label: "Automan",
    defaultSkillsDir: join(home, ".automan", "skills"),
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

// Optional mirror dir (currently only codex → ~/.agents/skills), returns null
// unless the ecosystem defines a mirror and its env flag is truthy.
export function mirrorDir(id) {
  const eco = ECOSYSTEMS[id];
  if (!eco || !eco.mirror) return null;
  const flag = process.env[eco.mirror.envVar];
  return flag && flag !== "0" && flag.toLowerCase() !== "false" ? eco.mirror.dir : null;
}
