// skilldev list — show each skill's name, version, and targets.

import { listSkills, loadSkill } from "../lib/skill.mjs";
import { info, c } from "../lib/log.mjs";

export default async function list({ flags }) {
  const names = await listSkills();
  if (names.length === 0) {
    info("No skills yet. Create one with: skilldev new <name>");
    return;
  }

  const rows = [];
  for (const name of names) {
    const skill = await loadSkill(name);
    rows.push({
      name,
      version: skill.meta.version || "?",
      targets: (skill.meta.targets || []).join(","),
    });
  }

  if (flags.json) {
    info(JSON.stringify(rows, null, 2));
    return;
  }

  const wName = Math.max(4, ...rows.map((r) => r.name.length));
  const wVer = Math.max(7, ...rows.map((r) => r.version.length));
  info(`${c.bold("NAME".padEnd(wName))}  ${c.bold("VERSION".padEnd(wVer))}  ${c.bold("TARGETS")}`);
  for (const r of rows) {
    info(`${r.name.padEnd(wName)}  ${r.version.padEnd(wVer)}  ${c.dim(r.targets)}`);
  }
}
