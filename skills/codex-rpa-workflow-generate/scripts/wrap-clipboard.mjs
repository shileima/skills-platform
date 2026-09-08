#!/usr/bin/env node
/** 将节点 JSON 包装为编辑器剪贴板格式 __JSON_DATA__...__JSON_DATA__ */

import { readFileSync, writeFileSync } from "node:fs";

const MARKER = "__JSON_DATA__";

export function wrapClipboardPayload(nodes) {
  const jsonString = JSON.stringify(nodes);
  return `${MARKER}${jsonString}${MARKER}`;
}

function main() {
  const inPath = process.argv[2];
  const outPath = process.argv[3];
  if (!inPath) {
    console.error("usage: wrap-clipboard.mjs <nodes.json> [clipboard.txt]");
    process.exit(2);
  }
  const nodes = JSON.parse(readFileSync(inPath, "utf8"));
  const payload = wrapClipboardPayload(nodes);
  if (outPath) {
    writeFileSync(outPath, payload);
    console.log(JSON.stringify({ ok: true, output: outPath, bytes: payload.length }));
  } else {
    process.stdout.write(payload);
  }
}

main();
