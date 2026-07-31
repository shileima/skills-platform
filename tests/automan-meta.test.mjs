import { test } from "node:test";
import assert from "node:assert/strict";
import { automanMeta, automanName } from "../src/lib/skill.mjs";

const base = {
  name: "my-skill",
  meta: {
    name: "my-skill",
    version: "0.0.1",
    author: "me",
    description: "does a thing",
    dependencies: [{ name: "dep", install: "echo hi" }],
    automan: { source: "user" },
  },
};

test("automanName uses metaName override when present", () => {
  assert.equal(automanName(base), "my-skill");
  const withOverride = { ...base, meta: { ...base.meta, automan: { source: "user", metaName: "legacy-name" } } };
  assert.equal(automanName(withOverride), "legacy-name");
});

test("automanMeta shape matches automan .meta.json", () => {
  const m = automanMeta(base);
  assert.deepEqual(m, {
    name: "my-skill",
    author: "me",
    description: "does a thing",
    version: "0.0.1",
    source: "user",
    dependencies: [{ name: "dep", install: "echo hi" }],
  });
});

test("automanMeta defaults source to user and deps to []", () => {
  const minimal = { name: "x", meta: { name: "x", version: "1.0.0" } };
  const m = automanMeta(minimal);
  assert.equal(m.source, "user");
  assert.deepEqual(m.dependencies, []);
});
