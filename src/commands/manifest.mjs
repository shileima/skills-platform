// skilldev manifest — generate repo-level plugin manifests so the whole skills/
// collection can be published to each ecosystem's marketplace. Secondary to the
// per-skill install/pack flow; all manifests point at ./skills.

import { spawnSync } from "node:child_process";
import { join } from "node:path";
import { repoRoot } from "../lib/skill.mjs";
import { readJson, writeJson } from "../lib/fsutil.mjs";
import { ok, info, warn, c } from "../lib/log.mjs";

function author() {
  const r = spawnSync("git", ["config", "user.name"], { encoding: "utf8" });
  return (r.status === 0 && r.stdout.trim()) || "mashilei";
}

export default async function manifest({ flags }) {
  const root = repoRoot();
  const pkg = await readJson(join(root, "package.json"));
  const name = pkg.name;
  const version = pkg.version;
  const description = pkg.description || "";
  const authorName = author();
  const dryRun = !!flags["dry-run"];

  const files = {
    ".claude-plugin/plugin.json": {
      name,
      description,
      version,
      author: { name: authorName },
      license: pkg.license || "MIT",
      keywords: pkg.keywords || [],
    },
    ".claude-plugin/marketplace.json": {
      name: `${name}-dev`,
      description,
      owner: { name: authorName },
      plugins: [{ name, description, version, source: "./", author: { name: authorName } }],
    },
    ".codex-plugin/plugin.json": {
      name,
      version,
      description,
      author: { name: authorName },
      license: pkg.license || "MIT",
      keywords: pkg.keywords || [],
      skills: "./skills/",
      hooks: {},
    },
    ".cursor-plugin/plugin.json": {
      name,
      displayName: name,
      description,
      version,
      author: { name: authorName },
      license: pkg.license || "MIT",
      keywords: pkg.keywords || [],
      skills: "./skills/",
    },
  };

  for (const [rel, obj] of Object.entries(files)) {
    const path = join(root, rel);
    if (dryRun) {
      info(`  ${c.dim("would write")} ${rel}`);
      continue;
    }
    await writeJson(path, obj);
    ok(`wrote ${rel}`);
  }

  if (dryRun) warn("dry-run: nothing written.");
  else info(c.green("Manifests generated (pointing at ./skills)."));
}
