#!/usr/bin/env bash
# 清空编排 canvas 上的业务节点，保留开始/结束/设置输入参数

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/resolve-cua-root.sh
source "$SKILL_DIR/scripts/lib/resolve-cua-root.sh"

CUA_ROOT="$(resolve_cua_root)"
bash "$SKILL_DIR/scripts/ensure-ready.sh" >/dev/null

osascript -e 'tell application "Google Chrome" to activate' -e 'delay 0.8' 2>/dev/null || true

bash "$CUA_ROOT/scripts/exec.sh" -t 180000 "
await (async () => {
  const app = 'com.google.Chrome';
  const sleep = (ms) => new Promise(r => setTimeout(r, ms));

  function idxFromLine(line) {
    return line ? parseInt(line.match(/^\\s*(\\d+)/)?.[1]) : null;
  }
  function urlOf(text) {
    return (text.match(/URL: ([^\\s,\\n]+)/) || [, ''])[1];
  }
  function isBusinessLine(line) {
    const t = line.replace(/\\t/g, ' ').trim();
    if (!/^\\d+\\s+(text|文本)/.test(t)) return false;
    if (/开始节点|结束节点|设置输入参数/.test(t)) return false;
    if (/^\\d+\\s+text\\s/.test(t)) return true;
    if (/^\\d+\\s+文本\\s+定位/.test(t)) return true;
    return false;
  }
  function listBusinessNodes(text) {
    return text.split('\\n')
      .filter(isBusinessLine)
      .map(l => ({ idx: idxFromLine(l), label: l.replace(/\\t/g, ' ').trim().slice(0, 80) }))
      .filter(n => Number.isInteger(n.idx));
  }
  function listCanvasSummary(text) {
    return text.split('\\n').filter(
      l => /^\\s*\\d+\\s+(text|文本)/.test(l.replace(/\\t/g, ' ')) &&
        /开始|结束|打开|导航|等待|获取|输入|模拟|滚动|截图|定位/.test(l) &&
        !/Placeholder|调试|小助手/.test(l)
    ).slice(0, 40);
  }

  let s = await sky.get_app_state({ app, disableDiff: true });
  const url = urlOf(s.text);
  if (!url.includes('rpa.sankuai.com') || !url.includes('workflow')) {
    nodeRepl.write(JSON.stringify({ ok: false, step: 'preflight', reason: '不在编排工作流配置页', url }));
    return;
  }

  const orchLine = s.text.split('\\n').find(l => /编排区/.test(l) && /按钮/.test(l));
  if (orchLine) {
    await sky.click({ app, element_index: idxFromLine(orchLine) });
    await sleep(400);
  }

  let deleted = 0;
  const maxRounds = 60;

  for (let round = 0; round < maxRounds; round++) {
    s = await sky.get_app_state({ app, disableDiff: true });
    const nodes = listBusinessNodes(s.text);
    if (nodes.length === 0) break;

    nodes.sort((a, b) => b.idx - a.idx);
    const target = nodes[0];
    await sky.get_app_state({ app, disableDiff: true });
    await sky.click({ app, element_index: target.idx });
    await sleep(350);
    await sky.press_key({ app, key: 'BackSpace' });
    await sleep(500);
    deleted++;
  }

  s = await sky.get_app_state({ app, disableDiff: true });
  const remaining = listBusinessNodes(s.text);
  const summary = listCanvasSummary(s.text);

  nodeRepl.write(JSON.stringify({
    ok: remaining.length === 0,
    step: 'clear-done',
    url: urlOf(s.text),
    deleted,
    remainingCount: remaining.length,
    remaining,
    canvasSummary: summary,
  }));
})();
"
