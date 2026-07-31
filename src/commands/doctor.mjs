// skilldev doctor — environment self-check.

import { ECOSYSTEMS, skillsDir, mirrorDir } from "../lib/ecosystems.mjs";
import { exists } from "../lib/fsutil.mjs";
import { hasZip } from "../lib/zip.mjs";
import { loadYaml } from "../lib/frontmatter.mjs";
import { info, ok, warn, c } from "../lib/log.mjs";

export default async function doctor() {
  info(c.bold("skilldev doctor"));

  // Node
  const major = Number(process.versions.node.split(".")[0]);
  if (major >= 18) ok(`node ${process.versions.node}`);
  else warn(`node ${process.versions.node} (>=18 recommended)`);

  // js-yaml
  try {
    await loadYaml();
    ok("js-yaml installed");
  } catch (e) {
    warn(e.message);
  }

  // zip
  if (hasZip()) ok("zip available (pack works)");
  else warn("zip not found — `skilldev pack` will fail");

  // Ecosystem dirs
  info(c.bold("\nEcosystems:"));
  for (const id of Object.keys(ECOSYSTEMS)) {
    const dir = skillsDir(id);
    const present = await exists(dir);
    const mark = present ? c.green("✓") : c.yellow("·");
    info(`  ${mark} ${id.padEnd(8)} ${dir}${present ? "" : c.dim("  (will be created on install)")}`);
    const mdir = mirrorDir(id);
    if (mdir) info(`      ${c.dim("mirror →")} ${mdir}`);
  }
}
