import { test } from "node:test";
import assert from "node:assert/strict";
import { promises as fs } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { copyIncluded, exists, ensureDir, writeText } from "../src/lib/fsutil.mjs";

test("copyIncluded copies present entries and skips missing ones", async () => {
  const root = await fs.mkdtemp(join(tmpdir(), "skilldev-"));
  const src = join(root, "src");
  const out = join(root, "out");
  await ensureDir(join(src, "reference"));
  await writeText(join(src, "SKILL.md"), "# skill");
  await writeText(join(src, "reference", "a.md"), "ref");
  // note: README.md and scripts/ intentionally absent

  const copied = await copyIncluded(
    ["SKILL.md", "README.md", "reference", "scripts"],
    src,
    out,
  );

  assert.deepEqual(copied.sort(), ["SKILL.md", "reference"]);
  assert.equal(await exists(join(out, "SKILL.md")), true);
  assert.equal(await exists(join(out, "reference", "a.md")), true);
  assert.equal(await exists(join(out, "README.md")), false);
  assert.equal(await exists(join(out, "scripts")), false);

  await fs.rm(root, { recursive: true, force: true });
});
