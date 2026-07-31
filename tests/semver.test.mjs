import { test } from "node:test";
import assert from "node:assert/strict";
import { isValid, bump, parse } from "../src/lib/semver.mjs";

test("validates x.y.z", () => {
  assert.equal(isValid("0.0.1"), true);
  assert.equal(isValid("1.2.3"), true);
  assert.equal(isValid("1.2"), false);
  assert.equal(isValid("v1.2.3"), false);
  assert.equal(isValid(undefined), false);
});

test("bumps patch/minor/major", () => {
  assert.equal(bump("1.2.3", "patch"), "1.2.4");
  assert.equal(bump("1.2.3", "minor"), "1.3.0");
  assert.equal(bump("1.2.3", "major"), "2.0.0");
});

test("bump accepts an explicit version", () => {
  assert.equal(bump("1.2.3", "2.5.0"), "2.5.0");
});

test("bump rejects garbage", () => {
  assert.throws(() => bump("1.2.3", "nope"));
});

test("parse returns components", () => {
  assert.deepEqual(parse("3.4.5"), { major: 3, minor: 4, patch: 5 });
});
