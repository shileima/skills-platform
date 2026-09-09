#!/usr/bin/env bash
# 清空编排 canvas 上的业务节点
#
# 主策略：选中开始节点 → Control+a 全选 → Delete
# 兜底策略：对残留业务节点逐条单击行 → 点右侧「删除」图标

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
  function canvasLines(text) {
    const lines = text.split('\\n');
    const start = lines.findIndex(l => l.includes('编辑器容器'));
    if (start < 0) return lines;
    const end = lines.findIndex((l, i) => i > start + 8 && (
      /Enter 发送，Shift \\+ Enter 换行/.test(l) ||
      /小助手出错了|失败节点：|instructionName/.test(l)
    ));
    return lines.slice(start, end > start ? end : start + 180);
  }
  function isBusinessLine(line) {
    const t = line.replace(/\\t/g, ' ').trim();
    if (!/^\\d+\\s+text\\s/.test(t)) return false;
    if (/开始节点|结束节点|设置输入参数|设置输出参数/.test(t)) return false;
    return /打开网页|导航到URL|等待页面|延迟|点击|获取|截图|刷新|输入|滚动|模拟|验证|等待\\s+页面|Cookie|关闭浏览器/.test(t);
  }
  function listBusinessNodes(text) {
    return canvasLines(text)
      .filter(isBusinessLine)
      .map(l => ({ idx: idxFromLine(l), label: l.replace(/\\t/g, ' ').trim().slice(0, 80) }))
      .filter(n => Number.isInteger(n.idx));
  }
  function listCanvasSummary(text) {
    return canvasLines(text).filter(
      l => /^\\s*\\d+\\s+(text|文本)/.test(l.replace(/\\t/g, ' ')) &&
        /开始|结束|打开|导航|等待|获取|输入|模拟|滚动|截图|定位|延迟|点击/.test(l) &&
        !/Placeholder|调试|小助手|失败节点/.test(l)
    ).slice(0, 40);
  }
  function findCanvasNode(text, keyword) {
    return canvasLines(text).find(
      l => l.includes(keyword) && /^\\s*\\d+\\s+(text|文本)/.test(l.replace(/\\t/g, ' '))
    );
  }
  function findDeleteBtnNearNode(lines, nodeIdx) {
    const lineNo = lines.findIndex(l => idxFromLine(l) === nodeIdx);
    if (lineNo < 0) return null;
    const slice = lines.slice(lineNo, Math.min(lines.length, lineNo + 20));
    const delLine = slice.find(l => /删除/.test(l) && /按钮|button|图像/i.test(l));
    return delLine ? idxFromLine(delLine) : null;
  }

  async function revealRowActions(nodeIdx) {
    // exec 环境无 sky.hover；单击节点行使右侧「删除」图标暴露（等效 hover）
    await sky.click({ app, element_index: nodeIdx });
    await sleep(450);
  }

  async function deleteNodeByHover(nodeIdx) {
    await revealRowActions(nodeIdx);
    const s = await sky.get_app_state({ app, disableDiff: true });
    const lines = s.text.split('\\n');
    const delIdx = findDeleteBtnNearNode(lines, nodeIdx);
    if (!delIdx) return { ok: false, nodeIdx, reason: 'hover 后未找到删除按钮' };
    await sky.click({ app, element_index: delIdx });
    await sleep(550);
    return { ok: true, nodeIdx, delIdx };
  }

  async function bulkSelectDelete(focusIdx) {
    await sky.click({ app, element_index: focusIdx });
    await sleep(400);
    await sky.press_key({ app, key: 'Control+a' });
    await sleep(350);
    await sky.press_key({ app, key: 'Delete' });
    await sleep(800);
  }

  async function clearRemainingByHover(maxRounds = 60) {
    const hoverDeleted = [];
    const hoverFailed = [];
    for (let round = 0; round < maxRounds; round++) {
      const s = await sky.get_app_state({ app, disableDiff: true });
      const nodes = listBusinessNodes(s.text);
      if (nodes.length === 0) break;
      nodes.sort((a, b) => b.idx - a.idx);
      const res = await deleteNodeByHover(nodes[0].idx);
      if (res.ok) hoverDeleted.push(res);
      else hoverFailed.push({ ...res, label: nodes[0].label });
    }
    return { hoverDeleted, hoverFailed };
  }

  let s = await sky.get_app_state({ app, disableDiff: true });
  const url = urlOf(s.text);
  if (!url.includes('rpa.sankuai.com') || !url.includes('workflow')) {
    nodeRepl.write(JSON.stringify({ ok: false, step: 'preflight', reason: '不在编排工作流配置页', url }));
    return;
  }

  const beforeCount = listBusinessNodes(s.text).length;

  // 1. 聚焦编排区 Tab
  const orchLine = s.text.split('\\n').find(l => /编排区/.test(l) && /按钮/.test(l));
  if (orchLine) {
    await sky.click({ app, element_index: idxFromLine(orchLine) });
    await sleep(400);
  }

  // 2. 选中开始节点 → Control+a → Delete
  s = await sky.get_app_state({ app, disableDiff: true });
  const startLine = findCanvasNode(s.text, '开始节点');
  const focusIdx = idxFromLine(startLine);

  if (!focusIdx) {
    nodeRepl.write(JSON.stringify({
      ok: false,
      step: 'find-start-node',
      reason: '未找到开始节点',
      canvasSummary: listCanvasSummary(s.text),
    }));
    return;
  }

  await bulkSelectDelete(focusIdx);

  s = await sky.get_app_state({ app, disableDiff: true });
  let remaining = listBusinessNodes(s.text);

  // 3. 兜底：逐条 hover 行 → 点右侧删除图标
  let hoverResult = { hoverDeleted: [], hoverFailed: [] };
  if (remaining.length > 0) {
    hoverResult = await clearRemainingByHover();
    s = await sky.get_app_state({ app, disableDiff: true });
    remaining = listBusinessNodes(s.text);
  }

  const summary = listCanvasSummary(s.text);
  const method = remaining.length === 0
    ? (hoverResult.hoverDeleted.length > 0 ? 'start-node-bulk-then-row-delete' : 'start-node-control-a-delete')
    : 'partial-failure';

  nodeRepl.write(JSON.stringify({
    ok: remaining.length === 0,
    step: 'clear-done',
    method,
    url: urlOf(s.text),
    focusIdx,
    beforeCount,
    deleted: beforeCount - remaining.length,
    remainingCount: remaining.length,
    remaining,
    hoverDeletedCount: hoverResult.hoverDeleted.length,
    hoverFailed: hoverResult.hoverFailed.slice(0, 5),
    canvasSummary: summary,
  }));
})();
"
