import { test } from "node:test";
import assert from "node:assert/strict";
import { parseFrontmatter, hasFrontmatter } from "../src/lib/frontmatter.mjs";

test("parses name/description frontmatter", async () => {
  const { data, body } = await parseFrontmatter("---\nname: foo\ndescription: bar\n---\n# Body\n");
  assert.equal(data.name, "foo");
  assert.equal(data.description, "bar");
  assert.match(body, /# Body/);
});

test("parses folded (>) multi-line description", async () => {
  const text = "---\nname: foo\ndescription: >\n  line one\n  line two\n---\nbody";
  const { data } = await parseFrontmatter(text);
  assert.equal(data.name, "foo");
  assert.match(data.description, /line one line two/);
});

test("no frontmatter returns empty data and full body", async () => {
  const { data, body } = await parseFrontmatter("# just markdown");
  assert.deepEqual(data, {});
  assert.equal(body, "# just markdown");
});

test("hasFrontmatter detects the block", () => {
  assert.equal(hasFrontmatter("---\nname: x\n---\n"), true);
  assert.equal(hasFrontmatter("# no"), false);
});
