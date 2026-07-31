// skilldev install — stage a skill and place it into each ecosystem's skills
// dir. Copies by default; --link symlinks the install dir to the staged build
// (re-run build/install to refresh). --dry-run prints destinations only.

import { join } from "node:path";
import { loadSkill } from "../lib/skill.mjs";
import { getAdapter, installRoots } from "../adapters/index.mjs";
import { copyPath, rmrf, symlinkForce } from "../lib/fsutil.mjs";
import { resolveTargets, stageSkill, distRoot } from "./build.mjs";
import { ok, step, info, warn, fail, c } from "../lib/log.mjs";

export default async function install({ positionals, flags }) {
  const name = positionals[0];
  if (!name) fail("usage: skilldev install <skill> [--target <id|all>] [--link] [--dry-run] [--install-deps]");

  const skill = await loadSkill(name);
  const targets = resolveTargets(skill, flags);
  const dryRun = !!flags["dry-run"];
  const link = !!flags.link;

  step(`installing ${c.bold(name)}@${skill.meta.version} → ${targets.join(", ")}${dryRun ? c.yellow(" (dry-run)") : ""}`);

  for (const t of targets) {
    const adapter = getAdapter(t);
    const roots = installRoots(adapter);
    const staged = join(distRoot(), t, name);

    if (!dryRun) await stageSkill(skill, t, staged);

    let primary = true;
    for (const root of roots) {
      const dest = join(root, name);
      if (dryRun) {
        info(`  ${c.dim("would " + (link ? "link" : "copy") + " →")} ${dest}`);
      } else if (link) {
        await symlinkForce(staged, dest);
        ok(`${t}: linked → ${dest}`);
      } else {
        await rmrf(dest);
        await copyPath(staged, dest);
        ok(`${t}: ${dest}`);
      }
      // Ecosystem-specific follow-up (e.g. automan deps) runs on the primary root.
      if (primary && typeof adapter.postInstall === "function") {
        await adapter.postInstall(skill, dest, { installDeps: !!flags["install-deps"], dryRun });
      }
      primary = false;
    }
  }

  if (dryRun) warn("dry-run: nothing written.");
  else info(c.green("Install complete."));
}
