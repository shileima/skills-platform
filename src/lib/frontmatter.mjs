// Parse the YAML frontmatter block at the top of a Markdown file.
// Supports the full YAML grammar (folded `>` / literal `|` scalars, etc.)
// via js-yaml, so multi-line skill descriptions parse correctly.
//
// js-yaml is loaded lazily so the CLI (help/doctor) still runs before
// `npm install`, and doctor can report the missing dependency cleanly.

const FRONTMATTER_RE = /^﻿?---\r?\n([\s\S]*?)\r?\n---\s*(?:\r?\n|$)/;

let _yaml;
export async function loadYaml() {
  if (!_yaml) {
    try {
      _yaml = (await import("js-yaml")).default;
    } catch {
      throw new Error("js-yaml is not installed — run `npm install` in the repo root");
    }
  }
  return _yaml;
}

// Returns { data, body }: data is the parsed frontmatter object ({} if none),
// body is the Markdown content after the closing `---`.
export async function parseFrontmatter(text) {
  const match = FRONTMATTER_RE.exec(text);
  if (!match) return { data: {}, body: text };
  const yaml = await loadYaml();
  const data = yaml.load(match[1]) || {};
  if (typeof data !== "object" || Array.isArray(data)) {
    throw new Error("frontmatter must be a YAML mapping");
  }
  return { data, body: text.slice(match[0].length) };
}

export function hasFrontmatter(text) {
  return FRONTMATTER_RE.test(text);
}
