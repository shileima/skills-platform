#!/usr/bin/env bash
set -euo pipefail

# 用法：send-markdown.sh [<receiver>] [--all-tab] [--marker REGEX]   # markdown on stdin
# receiver 可省略；若省略，则依次尝试：
#   1. 本地 automan 客户端登录人（~/Library/Preferences/automan/config.json.operator）
#   2. 仍为空时，退出并要求调用方指定接收人（不再使用任何写死的默认值）

RECEIVER=""
if [ $# -gt 0 ] && [[ "$1" != -* ]]; then
  RECEIVER="$1"
  shift
fi

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

MODULE_SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./resolve-receiver.sh
source "$MODULE_SCRIPTS_DIR/resolve-receiver.sh"
RECEIVER="$(resolve_dx_receiver "$RECEIVER")"

if [ -z "$RECEIVER" ]; then
  python3 - <<'PY'
import json
print(json.dumps({
  "ok": False,
  "error": "receiver_required",
  "hint": "未指定接收人，且未从 ~/Library/Preferences/automan/config.json 读取到 operator；请显式传入接收人姓名"
}, ensure_ascii=False))
PY
  exit 1
fi

SUMMARY="$(cat)"
if [ -z "$SUMMARY" ]; then
  python3 - <<'PY'
import json
print(json.dumps({"ok": False, "error": "empty_summary_on_stdin"}, ensure_ascii=False))
PY
  exit 1
fi

resolve_cua_root() {
  local root="${CUA_ROUTER_INSTALL_DIR:-${HOME}/.automan/claude-code-agents/cua-agent/skills/cua-router-basic}"
  if [ ! -f "$root/SKILL.md" ]; then
    root="${HOME}/.cursor/skills/cua-router-basic"
  fi
  if [ ! -f "$root/SKILL.md" ]; then
    root="${HOME}/.automan/skills/cua-router-basic"
  fi
  if [ ! -f "$root/SKILL.md" ]; then
    echo "找不到 cua-router-basic 技能" >&2
    exit 1
  fi
  printf '%s\n' "$root"
}

SKILL_ROOT="$(resolve_cua_root)"
bash "$SKILL_ROOT/scripts/ensure-ready.sh" >/dev/null

JS_FILE="${TMPDIR:-/tmp}/dx-send-markdown.$$.$RANDOM.mjs"
trap 'rm -f "$JS_FILE"' EXIT

python3 - "$RECEIVER" "$SUMMARY" "$CLICK_ALL_TAB" "$CONTENT_MARKER" > "$JS_FILE" <<'PY'
import json, sys
receiver, summary, click_all_tab, content_marker = sys.argv[1:5]
print(r'''
await (async () => {
  function emitResult(payload) {
    const text = typeof payload === "string" ? payload : JSON.stringify(payload);
    if (globalThis.nodeRepl && typeof globalThis.nodeRepl.write === "function") {
      globalThis.nodeRepl.write(text);
    } else {
      console.log(text);
    }
  }
  const receiver = RECEIVER_PLACEHOLDER;
  const summary = SUMMARY_PLACEHOLDER;
  const shouldClickAllTab = CLICK_ALL_TAB_PLACEHOLDER;
  const contentMarker = CONTENT_MARKER_PLACEHOLDER;
  const app = "cn.neixin.pc";
  const sky = globalThis.sky;

  function escapeRegExp(text) {
    return String(text).replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&");
  }
  const { execFileSync } = await import("node:child_process");
  const fs = await import("node:fs");
  const os = await import("node:os");
  const path = await import("node:path");

  function parseIdx(line) {
    const m = String(line || "").match(/^\s*(\d+)/);
    return m ? parseInt(m[1], 10) : null;
  }

  async function freshState() {
    return sky.get_app_state({ app, disableDiff: true });
  }

  function readClipboardText() {
    try {
      return execFileSync("/usr/bin/pbpaste", { encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] });
    } catch (_) {
      return null;
    }
  }

  // 将文本写入剪贴板：优先 pbcopy；失败时通过临时文件走 osascript，避免把文本作为
  // argv 传给 AppleScript（会触发 -10006「不能将 clipboard 设置为 …」）。
  // 返回值统一为结构化对象，不抛异常，方便上层把失败原因带回最终 payload。
  function writeClipboardOnce(payload) {
    try {
      execFileSync("/usr/bin/pbcopy", { input: payload, stdio: ["pipe", "ignore", "ignore"] });
      return { ok: true, method: "pbcopy" };
    } catch (pbErr) {
      const pbcopyError = String((pbErr && pbErr.message) || pbErr);
      const tmp = path.join(os.tmpdir(), `dx-clipboard-${Date.now()}.txt`);
      try {
        fs.writeFileSync(tmp, payload, { encoding: "utf8" });
        // 用 POSIX file + «class utf8» 读回，AppleScript 端不再依赖 argv 解析
        const script = [
          'on run argv',
          '  set p to POSIX file (item 1 of argv)',
          '  set fh to open for access p',
          '  try',
          '    set t to (read fh as «class utf8»)',
          '  on error errMsg number errNum',
          '    close access fh',
          '    error errMsg number errNum',
          '  end try',
          '  close access fh',
          '  set the clipboard to t',
          'end run',
        ].join('\n');
        execFileSync("/usr/bin/osascript", ["-e", script, tmp], { stdio: ["ignore", "ignore", "pipe"] });
        return { ok: true, method: "osascript_file", pbcopyError };
      } catch (asErr) {
        return {
          ok: false,
          method: "none",
          pbcopyError,
          osascriptError: String((asErr && asErr.message) || asErr),
        };
      } finally {
        try { fs.unlinkSync(tmp); } catch (_) {}
      }
    }
  }

  // 写入 + pbpaste 校验，不一致就重试一次
  function writeClipboard(text) {
    const payload = String(text ?? "");
    const attempts = [];
    for (let i = 0; i < 2; i++) {
      const w = writeClipboardOnce(payload);
      attempts.push(w);
      if (!w.ok) continue;
      const readBack = readClipboardText();
      if (readBack !== null && readBack === payload) {
        return { ok: true, method: w.method, attempts, verified: true };
      }
      attempts[attempts.length - 1] = { ...w, verified: false, readBackLen: readBack === null ? null : readBack.length };
    }
    const last = attempts[attempts.length - 1] || {};
    return {
      ok: last.ok === true, // 写入成功但未 pbpaste 校验通过，仍视为可尝试粘贴
      method: last.method || "none",
      attempts,
      verified: false,
      pbcopyError: last.pbcopyError,
      osascriptError: last.osascriptError,
    };
  }

  async function stablePaste(elementIndex, text, verify) {
    const clipboard = writeClipboard(text);
    await sky.click({ app, element_index: elementIndex });
    await new Promise(r => setTimeout(r, 300));

    if (clipboard.ok) {
      await sky.press_key({ app, key: "Command+a" });
      await new Promise(r => setTimeout(r, 100));
      await sky.press_key({ app, key: "Command+v" });
      await new Promise(r => setTimeout(r, 700));
    } else {
      try {
        await sky.set_value({ app, element_index: elementIndex, value: text });
      } catch (err) {
        return { state: null, ok: false, error: "clipboard_write_failed", clipboard, setValueError: String(err) };
      }
      await new Promise(r => setTimeout(r, 700));
    }

    const state = await freshState();
    return { state, ok: verify(state.text), clipboard };
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
    const escaped = escapeRegExp(name);
    const exact = new RegExp(`\\d+\\s+(container|文本)\\s+${escaped}$`);
    const scoped = lines.filter(l => {
      const idx = parseIdx(l);
      return idx !== null && idx > searchIdx && idx < searchIdx + 300;
    });
    const exactLine = scoped.find(l => exact.test(l.trim()))
      || scoped.find(l => l.includes(`container ${name}`) && !l.includes("、"))
      || scoped.find(l => l.includes(`文本 ${name}`) && !l.includes("、"));
    if (exactLine) return exactLine;

    const contactContainers = scoped.filter(l => /^\s*\d+\s+container\s+/.test(l) && !/搜索|消息|通讯录|日历|工作台/.test(l));
    if (contactContainers.length === 1) return contactContainers[0];

    const contactTexts = scoped.filter(l => /^\s*\d+\s+文本\s+/.test(l) && !/搜索|消息|通讯录|日历|工作台/.test(l) && !l.includes("、"));
    return contactTexts[0] || contactContainers[0] || null;
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
      || null;
  }

  async function maximizeWindow() {
    const state = await freshState();
    const screenshotWidth = state.screenshotWidth;
    const screenshotHeight = state.screenshotHeight;
    if (!screenshotWidth || !screenshotHeight) {
      return {
        ok: true,
        method: "skip_missing_dimensions",
        hasScreenshot: Boolean(state.screenshot),
      };
    }
    const clickX = Math.round(screenshotWidth / 2);
    const clickY = Math.round(screenshotHeight * 0.02);
    await sky.click({ app, x: clickX, y: clickY, click_count: 2 });
    await new Promise(r => setTimeout(r, 1200));
    return {
      ok: true,
      method: "coordinate_double_click",
      screenshotWidth,
      screenshotHeight,
      clickX,
      clickY,
    };
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

  function findMarkdownInputLine(lines) {
    return lines.find(l => /文本输入区/.test(l) && /请输入内容/.test(l));
  }

  function findMarkdownSendLine(lines) {
    const sendLines = lines.filter(l => /^\s*\d+\s+按钮\s+发送\s*$/.test(l));
    return sendLines[sendLines.length - 1] || null;
  }

  function isMarkdownEditorOpen(text) {
    return /Window: "Markdown编辑器"|发送\s*Markdown\s*消息/.test(text) && /请输入内容|按钮\s+发送/.test(text);
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
    emitResult({ ok: false, error: "search_box_not_found", preview: state.text.slice(0, 1200) });
    return;
  }

  let pasted = await stablePaste(searchIdx, receiver, text => text.includes(receiver));
  if (!pasted.ok) {
    emitResult({
      ok: false,
      error: pasted.error || "receiver_search_input_failed",
      receiver,
      clipboard: pasted.clipboard,
      preview: pasted.state ? pasted.state.text.slice(0, 1200) : null,
    });
    return;
  }
  state = pasted.state;
  lines = state.text.split("\n");

  const contactLine = findContactLine(lines, receiver, searchIdx);
  if (!contactLine) {
    emitResult({ ok: false, error: "receiver_not_found", receiver, preview: state.text.slice(0, 1200) });
    return;
  }

  const receiverIdx = parseIdx(contactLine);
  await sky.click({ app, element_index: receiverIdx });
  await new Promise(r => setTimeout(r, 1000));

  const maximize = await maximizeWindow();
  if (!maximize.ok) {
    emitResult({ ok: false, error: "maximize_window_failed", receiver, receiverIdx, maximize });
    return;
  }
  await new Promise(r => setTimeout(r, 800));

  const editorOpen = await openMarkdownEditor();
  if (!editorOpen.ok) {
    emitResult({ ok: false, receiver, receiverIdx, maximize, ...editorOpen });
    return;
  }

  state = await freshState();
  lines = state.text.split("\n");
  const markdownInputLine = findMarkdownInputLine(lines);
  if (!markdownInputLine) {
    emitResult({ ok: false, error: "markdown_input_not_found", receiver, receiverIdx, maximize, editorOpen, editorPreview: state.text.slice(0, 1000) });
    return;
  }

  const markdownInputIdx = parseIdx(markdownInputLine);
  let filled = await stablePaste(markdownInputIdx, summary, contentOk);
  if (!filled.ok) {
    emitResult({
      ok: false,
      error: filled.error || "markdown_input_failed",
      receiver,
      receiverIdx,
      maximize,
      editorOpen,
      markdownInputIdx,
      clipboard: filled.clipboard,
      editorPreview: filled.state ? filled.state.text.slice(0, 1000) : null,
    });
    return;
  }

  let filledState = filled.state;
  let filledLines = filledState.text.split("\n");
  let sendLine = findMarkdownSendLine(filledLines);
  let hasContent = contentOk(filledState.text);
  const hasReceiver = filledState.text.includes(receiver);

  if (!sendLine || !hasContent) {
    emitResult({ ok: false, error: "markdown_editor_not_ready", hasSend: !!sendLine, hasContent, hasReceiver, preview: filledState.text.slice(0, 1000) });
    return;
  }

  let sendIdx = parseIdx(sendLine);
  await sky.click({ app, element_index: sendIdx });
  await new Promise(r => setTimeout(r, 1200));

  let after = await freshState();
  let editorStillOpen = isMarkdownEditorOpen(after.text);
  let sentLikely = !editorStillOpen;

  if (!sentLikely && editorStillOpen) {
    const retryLines = after.text.split("\n");
    const retrySendLine = findMarkdownSendLine(retryLines);
    if (retrySendLine) {
      sendIdx = parseIdx(retrySendLine);
      await sky.click({ app, element_index: sendIdx });
      await new Promise(r => setTimeout(r, 1500));
      after = await freshState();
      editorStillOpen = isMarkdownEditorOpen(after.text);
      sentLikely = !editorStillOpen;
    }
  }

  emitResult({
    ok: sentLikely,
    error: sentLikely ? undefined : "send_button_click_not_confirmed",
    receiver,
    receiverIdx,
    maximize,
    editorOpen,
    markdownInputIdx,
    sendIdx,
    sentLikely,
    editorStillOpen,
    clipboard: filled.clipboard,
    summaryPreview: summary.slice(0, 200),
    afterPreview: sentLikely ? undefined : after.text.slice(0, 1000)
  });
})()
'''.replace('RECEIVER_PLACEHOLDER', json.dumps(receiver, ensure_ascii=False))
   .replace('SUMMARY_PLACEHOLDER', json.dumps(summary, ensure_ascii=False))
   .replace('CLICK_ALL_TAB_PLACEHOLDER', 'true' if click_all_tab == '1' else 'false')
   .replace('CONTENT_MARKER_PLACEHOLDER', json.dumps(content_marker, ensure_ascii=False)))
PY

set +e
FETCH_RESULT="$(bash "$SKILL_ROOT/scripts/exec.sh" -t 600000 -f "$JS_FILE" 2>&1)"
EXEC_RC=$?
set -e
echo "$FETCH_RESULT"
LAST_LINE="$(printf '%s\n' "$FETCH_RESULT" | tail -n 1)"
if [ "$EXEC_RC" -ne 0 ]; then
  python3 - "$EXEC_RC" "$LAST_LINE" <<'PY'
import json
import sys

rc = int(sys.argv[1])
last_line = sys.argv[2]
try:
    payload = json.loads(last_line)
except Exception:
    payload = {"ok": False, "error": "dx_exec_failed", "execRc": rc, "lastLine": last_line}
else:
    payload.setdefault("ok", False)
    payload.setdefault("error", "dx_exec_failed")
    payload["execRc"] = rc
print(json.dumps(payload, ensure_ascii=False))
PY
  exit "$EXEC_RC"
fi
python3 -c 'import json,sys; d=json.loads(sys.argv[1]); sys.exit(0 if d.get("ok") else 1)' "$LAST_LINE"
