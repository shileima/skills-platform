// Adapter registry. To add an ecosystem: implement src/adapters/<id>.mjs and
// register it here (and add its paths to src/lib/ecosystems.mjs).

import claude from "./claude.mjs";
import codex from "./codex.mjs";
import cursor from "./cursor.mjs";
import automan from "./automan.mjs";

export const adapters = { claude, codex, cursor, automan };

export function getAdapter(id) {
  const a = adapters[id];
  if (!a) throw new Error(`no adapter for ecosystem: ${id}`);
  return a;
}

// Install roots for an adapter: its primary skillsDir plus any extras (mirrors).
export function installRoots(adapter) {
  const roots = [adapter.skillsDir()];
  if (typeof adapter.extraSkillsDirs === "function") {
    roots.push(...adapter.extraSkillsDirs());
  }
  return roots;
}
