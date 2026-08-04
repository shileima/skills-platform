import { test } from "node:test";
import assert from "node:assert/strict";
import { promises as fs } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { loadSkill } from "../src/lib/skill.mjs";
import { stageModules, moduleDir, listModules } from "../src/lib/modules.mjs";
import { exists } from "../src/lib/fsutil.mjs";
import { stageSkill } from "../src/commands/build.mjs";

test("listModules includes dx-send-markdown", async () => {
  const names = await listModules();
  assert.equal(names.includes("dx-send-markdown"), true);
});

test("stageModules copies module into skill output", async () => {
  const root = await fs.mkdtemp(join(tmpdir(), "skilldev-mod-"));
  const out = join(root, "out");
  const skill = await loadSkill("codex-github-trending-today");
  const staged = await stageModules(skill, out);
  assert.deepEqual(staged, ["dx-send-markdown"]);
  assert.equal(await exists(join(out, "modules", "dx-send-markdown", "MODULE.md")), true);
  assert.equal(await exists(join(out, "modules", "dx-send-markdown", "scripts", "send-markdown.sh")), true);
  await fs.rm(root, { recursive: true, force: true });
});

test("stageSkill bundles modules with skill files", async () => {
  const root = await fs.mkdtemp(join(tmpdir(), "skilldev-stage-"));
  const out = join(root, "dist", "codex");
  const skill = await loadSkill("codex-dx-unread-messages");
  await stageSkill(skill, "codex", out);
  assert.equal(await exists(join(out, "SKILL.md")), true);
  assert.equal(await exists(join(out, "modules", "dx-send-markdown", "scripts", "send-markdown.sh")), true);
  await fs.rm(root, { recursive: true, force: true });
});

test("moduleDir resolves dx-send-markdown", async () => {
  assert.equal(await exists(join(moduleDir("dx-send-markdown"), "MODULE.md")), true);
});
