#!/usr/bin/env bash
# 将节点 JSON 粘贴到空编排工作流 canvas（开始节点下方）

set -euo pipefail

CLIPBOARD_FILE="${1:-}"
if [ -z "$CLIPBOARD_FILE" ] || [ ! -f "$CLIPBOARD_FILE" ]; then
  echo "usage: $0 <clipboard-payload.txt>" >&2
  exit 2
fi

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/resolve-cua-root.sh
source "$SKILL_DIR/scripts/lib/resolve-cua-root.sh"

CUA_ROOT="$(resolve_cua_root)"
bash "$SKILL_DIR/scripts/ensure-ready.sh" >/dev/null

osascript -e 'tell application "Google Chrome" to activate' -e 'delay 0.8' 2>/dev/null || true

/usr/bin/pbcopy < "$CLIPBOARD_FILE"

bash "$CUA_ROOT/scripts/exec.sh" -t 120000 "
await (async () => {
  const app = 'com.google.Chrome';
  const sleep = (ms) => new Promise(r => setTimeout(r, ms));

  function idxFromLine(line) {
    return line ? parseInt(line.match(/^\\s*(\\d+)/)?.[1]) : null;
  }
  function urlOf(text) {
    return (text.match(/URL: ([^\\s,\\n]+)/) || [, ''])[1];
  }
  function findCanvasNode(text, keyword) {
    return text.split('\\n').find(
      l => l.includes(keyword) && /^\\s*\\d+\\s+(text|文本)/.test(l.replace(/\\t/g, ' '))
    );
  }
  function listCanvasNodes(text) {
    return text.split('\\n').filter(
      l => /^\\s*\\d+\\s+(text|文本)/.test(l.replace(/\\t/g, ' ')) &&
        /开始|结束|打开|导航|等待|输入|点击|获取|滚动|截图|刷新|模拟|定位|url|github|bilibili|codex|issue|commit|jd|tmall|iphone/i.test(l) &&
        !/开始时间|失败节点|小助手|Placeholder|调试/.test(l)
    ).slice(0, 40);
  }
  function countBusinessNodes(text) {
    return text.split('\\n').filter(l => {
      const t = l.replace(/\\t/g, ' ').trim();
      if (!/^\\d+\\s+text\\s/.test(t)) return false;
      return !/开始节点|结束节点|设置输入参数/.test(t);
    }).length;
  }

  let s = await sky.get_app_state({ app, disableDiff: true });
  const url = urlOf(s.text);
  if (!url.includes('rpa.sankuai.com') || !url.includes('workflow')) {
    nodeRepl.write(JSON.stringify({ ok: false, step: 'preflight', reason: '不在编排工作流配置页', url }));
    return;
  }

  // 聚焦编排区
  const orchLine = s.text.split('\\n').find(l => /编排区/.test(l) && /按钮/.test(l));
  if (orchLine) {
    await sky.click({ app, element_index: idxFromLine(orchLine) });
    await sleep(400);
  }

  s = await sky.get_app_state({ app, disableDiff: true });
  const startLine = findCanvasNode(s.text, '开始节点');
  const startIdx = idxFromLine(startLine);
  if (!startIdx) {
    nodeRepl.write(JSON.stringify({
      ok: false,
      step: 'find-start-node',
      reason: '未找到开始节点 canvas 行',
      hints: listCanvasNodes(s.text),
    }));
    return;
  }

  await sky.click({ app, element_index: startIdx });
  await sleep(500);
  // 选中开始节点后直接 Cmd+V：编辑器会在其后插入段落并粘贴（无需先 Enter）
  await sky.press_key({ app, key: 'Command+v' });
  await sleep(2500);

  s = await sky.get_app_state({ app, disableDiff: true });
  const seq = listCanvasNodes(s.text);

  const bizCount = countBusinessNodes(s.text);
  nodeRepl.write(JSON.stringify({
    ok: bizCount >= 2 && seq.some(l => /打开网页|导航到URL/.test(l)),
    step: 'paste-done',
    url: urlOf(s.text),
    businessNodeCount: bizCount,
    canvasSummary: seq,
  }));
})();
"
