#!/usr/bin/env bash
set -euo pipefail

RECEIVER="${1:?usage: send-markdown.sh <receiver> [--all-tab] [--marker REGEX]  # markdown on stdin}"
shift

CLICK_ALL_TAB=0
CONTENT_MARKER=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all-tab)
      CLICK_ALL_TAB=1
      shift
      ;;
    --marker)
      CONTENT_MARKER="${2:?--marker requires regex}"
      shift 2
      ;;
    *)
      echo "unknown option: $1" >&2
      exit 1
      ;;
  esac
done

SUMMARY="$(cat)"
if [ -z "$SUMMARY" ]; then
  python3 - <<'PY'
import json
print(json.dumps({"ok": False, "error": "empty_summary_on_stdin"}, ensure_ascii=False))
PY
  exit 1
fi

resolve_cua_root() {
  local root="${CUA_ROUTER_INSTALL_DIR:-${HOME}/.automan/skills/cua-router-basic}"
  if [ ! -f "$root/SKILL.md" ]; then
    root="${HOME}/.cursor/skills/cua-router-basic"
  fi
  if [ ! -f "$root/SKILL.md" ]; then
    root="${HOME}/.automan/claude-code-agents/cua-agent/skills/cua-router-basic"
  fi
  if [ ! -f "$root/SKILL.md" ]; then
    echo "找不到 cua-router-basic 技能" >&2
    exit 1
  fi
  printf '%s\n' "$root"
}

SKILL_ROOT="$(resolve_cua_root)"
bash "$SKILL_ROOT/scripts/daemon.sh" start >/dev/null
bash "$SKILL_ROOT/scripts/exec.sh" 'nodeRepl.write("ok")' >/dev/null

JS_FILE="$(mktemp -t dx-send-markdown.XXXXXX.js)"
trap 'rm -f "$JS_FILE"' EXIT

python3 - "$RECEIVER" "$SUMMARY" "$CLICK_ALL_TAB" "$CONTENT_MARKER" > "$JS_FILE" <<'PY'
import json, sys
receiver, summary, click_all_tab, content_marker = sys.argv[1:5]
print(r'''
await (async () => {
  const receiver = RECEIVER_PLACEHOLDER;
  const summary = SUMMARY_PLACEHOLDER;
  const shouldClickAllTab = CLICK_ALL_TAB_PLACEHOLDER;
  const contentMarker = CONTENT_MARKER_PLACEHOLDER;
  const app = "cn.neixin.pc";
  const { sky } = await import("@oai/sky");
  const { execFileSync } = await import("node:child_process");

  function parseIdx(line) {
    const m = String(line || "").match(/^\s*(\d+)/);
    return m ? parseInt(m[1], 10) : null;
  }

  async function freshState() {
    return sky.get_app_state({ app, disableDiff: true });
  }

  async function clickAllTab(stateText) {
    const tabLine = stateText.split("\n").find(l => /^\s*\d+\s+(按钮|text|文本)\s+全部/.test(l));
    if (!tabLine) return { clicked: false };
    await sky.click({ app, element_index: parseIdx(tabLine) });
    await new Promise(r => setTimeout(r, 800));
    return { clicked: true };
  }

  function findSearchLine(lines) {
    return lines.find(l => /文本栏.*搜索/.test(l) || /Placeholder:\s*搜索/.test(l));
  }

  function findContactLine(lines, name, searchIdx) {
    const escaped = name.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const exact = new RegExp(`\\d+\\s+(container|文本)\\s+${escaped}$`);
    return lines.find(l => {
      const idx = parseIdx(l);
      return idx !== null && idx > searchIdx && idx < searchIdx + 250 && exact.test(l.trim());
    }) || lines.find(l => l.includes(`container ${name}`) && !l.includes("、"))
      || lines.find(l => l.includes(`文本 ${name}`) && !l.includes("、"));
  }

  function findMarkdownButtonLine(lines, inputIdx) {
    if (inputIdx === null) return null;
    const candidates = lines.filter(l => {
      const idx = parseIdx(l);
      return idx !== null && idx < inputIdx && idx >= inputIdx - 120 && /^\s*\d+\s+按钮\s+/.test(l);
    });
    return candidates.find(l => /\uE124/.test(l))
      || candidates.find(l => /\uE04D/.test(l))
      || candidates.find(l => /\uE01E/.test(l))
      || candidates[candidates.length - 1]
      || null;
  }

  function getWindowWidth() {
    let windowWidth = 1512;
    const scripts = [
      'tell application "System Events" to tell (first application process whose bundle identifier is "cn.neixin.pc") to get item 1 of (size of window 1)',
      'tell application "System Events" to tell process "大象" to get item 1 of (size of window 1)',
    ];
    for (const script of scripts) {
      try {
        const out = execFileSync("/usr/bin/osascript", ["-e", script], { encoding: "utf8" }).trim();
        const w = parseInt(out, 10);
        if (Number.isFinite(w) && w > 100) return w;
      } catch (_) {}
    }
    return windowWidth;
  }

  async function maximizeWindow() {
    const windowWidth = getWindowWidth();
    const clickX = Math.round(windowWidth / 2);
    const clickY = 6;
    await freshState();
    await sky.click({ app, x: clickX, y: clickY, click_count: 2 });
    await new Promise(r => setTimeout(r, 1200));
    return { windowWidth, clickX, clickY };
  }

  async function openMarkdownEditor() {
    let state = await freshState();
    let lines = state.text.split("\n");

    if (/Secondary Actions: Cancel/.test(state.text) && /发送\s*Markdown\s*消息/.test(state.text) && !/Markdown编辑器/.test(state.text)) {
      return { ok: false, error: "markdown_menu_open", hint: "请先关闭大象中的 Markdown 浮层后重试" };
    }

    if (/Markdown编辑器/.test(state.text) && /请输入内容/.test(state.text)) {
      return { ok: true, method: "already_open" };
    }

    let markdownMenuLine = lines.find(l => /发送\s*Markdown\s*消息/.test(l));
    if (markdownMenuLine) {
      const menuIdx = parseIdx(markdownMenuLine);
      await sky.click({ app, element_index: menuIdx });
      await new Promise(r => setTimeout(r, 800));
      return { ok: true, menuIdx, method: "direct_menu_after_maximize" };
    }

    const inputLine = lines.find(l => /文本输入区/.test(l) && /说点什么/.test(l));
    const inputIdx = inputLine ? parseIdx(inputLine) : null;
    const markdownButtonLine = findMarkdownButtonLine(lines, inputIdx);
    if (!markdownButtonLine) {
      const markdownPreview = lines.filter(l => /Markdown|Mark|发送|按钮|文本输入区/.test(l)).slice(-40);
      return { ok: false, error: "markdown_button_not_found", inputIdx, markdownPreview };
    }

    const markdownIdx = parseIdx(markdownButtonLine);
    await sky.click({ app, element_index: markdownIdx });
    await new Promise(r => setTimeout(r, 800));

    state = await freshState();
    lines = state.text.split("\n");
    markdownMenuLine = lines.find(l => /发送\s*Markdown\s*消息/.test(l));
    if (markdownMenuLine && !/Markdown编辑器/.test(state.text)) {
      const menuIdx = parseIdx(markdownMenuLine);
      await sky.click({ app, element_index: menuIdx });
      await new Promise(r => setTimeout(r, 800));
      return { ok: true, menuIdx, markdownIdx, method: "toolbar_then_menu" };
    }

    if (/Markdown编辑器/.test(state.text)) {
      return { ok: true, markdownIdx, method: "toolbar_direct" };
    }

    return { ok: false, error: "markdown_menu_not_found", markdownIdx, preview: state.text.slice(0, 1000) };
  }

  function contentOk(text) {
    if (contentMarker) {
      try { return new RegExp(contentMarker).test(text); } catch (_) { return text.includes(contentMarker); }
    }
    return summary.trim().length > 0 && text.includes(summary.trim().slice(0, Math.min(40, summary.trim().length)));
  }

  const daxiangApp = "/Applications/大象.app";
  try { execFileSync("/usr/bin/open", [daxiangApp]); } catch (_) {
    try { execFileSync("/usr/bin/open", ["-b", "cn.neixin.pc"]); } catch (_) {}
  }
  await new Promise(r => setTimeout(r, 800));
  try { execFileSync("/usr/bin/osascript", ["-e", 'tell application "大象" to activate']); } catch (_) {}
  await new Promise(r => setTimeout(r, 500));

  await freshState();
  await sky.press_key({ app, key: "Escape" });
  await new Promise(r => setTimeout(r, 400));

  let state = await freshState();
  let lines = state.text.split("\n");

  if (shouldClickAllTab) {
    await clickAllTab(state.text);
    state = await freshState();
    lines = state.text.split("\n");
  }

  const msgNav = lines.find(l => /^\s*\d+\s+文本\s+消息/.test(l) && parseIdx(l) < 40);
  if (msgNav) {
    await sky.click({ app, element_index: parseIdx(msgNav) });
    await new Promise(r => setTimeout(r, 500));
    state = await freshState();
    lines = state.text.split("\n");
  }

  const searchLine = findSearchLine(lines);
  const searchIdx = parseIdx(searchLine);
  if (!searchIdx) {
    nodeRepl.write(JSON.stringify({ ok: false, error: "search_box_not_found", preview: state.text.slice(0, 1200) }));
    return;
  }

  await sky.set_value({ app, element_index: searchIdx, value: receiver });
  await new Promise(r => setTimeout(r, 1000));
  state = await freshState();
  lines = state.text.split("\n");

  const contactLine = findContactLine(lines, receiver, searchIdx);
  if (!contactLine) {
    nodeRepl.write(JSON.stringify({ ok: false, error: "receiver_not_found", receiver, preview: state.text.slice(0, 1200) }));
    return;
  }

  const receiverIdx = parseIdx(contactLine);
  await sky.click({ app, element_index: receiverIdx });
  await new Promise(r => setTimeout(r, 1000));

  const maximize = await maximizeWindow();

  const editorOpen = await openMarkdownEditor();
  if (!editorOpen.ok) {
    nodeRepl.write(JSON.stringify({ ok: false, receiver, receiverIdx, maximize, ...editorOpen }));
    return;
  }

  state = await freshState();
  lines = state.text.split("\n");
  const markdownInputLine = lines.find(l => /文本输入区/.test(l) && /请输入内容/.test(l));
  if (!markdownInputLine) {
    nodeRepl.write(JSON.stringify({ ok: false, error: "markdown_input_not_found", receiver, receiverIdx, maximize, editorOpen, editorPreview: state.text.slice(0, 1000) }));
    return;
  }

  const markdownInputIdx = parseIdx(markdownInputLine);
  await sky.set_value({ app, element_index: markdownInputIdx, value: summary });
  await new Promise(r => setTimeout(r, 500));

  const filledState = await freshState();
  const sendLine = filledState.text.split("\n").find(l => /^\s*\d+\s+按钮\s+发送/.test(l));
  const hasContent = contentOk(filledState.text);
  const hasReceiver = filledState.text.includes(receiver);

  if (!sendLine || !hasContent) {
    nodeRepl.write(JSON.stringify({ ok: false, error: "markdown_editor_not_ready", hasSend: !!sendLine, hasContent, hasReceiver, preview: filledState.text.slice(0, 1000) }));
    return;
  }

  const sendIdx = parseIdx(sendLine);
  await sky.click({ app, element_index: sendIdx });
  await new Promise(r => setTimeout(r, 1200));
  const after = await freshState();
  nodeRepl.write(JSON.stringify({
    ok: true,
    receiver,
    receiverIdx,
    maximize,
    editorOpen,
    markdownInputIdx,
    sendIdx,
    sentLikely: contentOk(after.text),
    summaryPreview: summary.slice(0, 200)
  }));
})()
'''.replace('RECEIVER_PLACEHOLDER', json.dumps(receiver, ensure_ascii=False))
   .replace('SUMMARY_PLACEHOLDER', json.dumps(summary, ensure_ascii=False))
   .replace('CLICK_ALL_TAB_PLACEHOLDER', 'true' if click_all_tab == '1' else 'false')
   .replace('CONTENT_MARKER_PLACEHOLDER', json.dumps(content_marker, ensure_ascii=False)))
PY

bash "$SKILL_ROOT/scripts/exec.sh" -t 90000 -f "$JS_FILE"
