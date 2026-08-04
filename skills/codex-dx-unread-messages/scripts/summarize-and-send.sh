#!/usr/bin/env bash
set -euo pipefail

RECEIVER="${1:-马世磊}"
TIME_LABEL="${2:-$(date '+%Y-%m-%d %H:%M左右')}"

SKILL_ROOT="${CUA_ROUTER_INSTALL_DIR:-${HOME}/.automan/skills/cua-router-basic}"
if [ ! -f "$SKILL_ROOT/SKILL.md" ]; then
  SKILL_ROOT="${HOME}/.cursor/skills/cua-router-basic"
fi
if [ ! -f "$SKILL_ROOT/SKILL.md" ]; then
  SKILL_ROOT="${HOME}/.automan/claude-code-agents/cua-agent/skills/cua-router-basic"
fi

bash "$SKILL_ROOT/scripts/daemon.sh" start >/dev/null
bash "$SKILL_ROOT/scripts/exec.sh" 'nodeRepl.write("ok")' >/dev/null

# 优先用 .app 路径启动（部分环境下 open -b 无法解析 bundle，但 plist 仍为 cn.neixin.pc）
DAXIANG_APP="${DAXIANG_APP:-/Applications/大象.app}"
if [ -d "$DAXIANG_APP" ]; then
  open "$DAXIANG_APP" >/dev/null 2>&1 || true
else
  open -b cn.neixin.pc >/dev/null 2>&1 || true
fi
sleep 0.8

MAXIMIZE_DAXIANG_OSASCRIPT='tell application "System Events"
  set daxiangProc to missing value
  try
    set daxiangProc to first application process whose bundle identifier is "cn.neixin.pc"
  end try
  if daxiangProc is missing value then
    if exists process "大象" then set daxiangProc to process "大象"
  end if
  if daxiangProc is missing value then error "daxiang process not found"
  set frontmost of daxiangProc to true
  tell daxiangProc
    set position of window 1 to {0, 33}
    set size of window 1 to {1512, 850}
  end tell
end tell'

if ! osascript -e "$MAXIMIZE_DAXIANG_OSASCRIPT" >/dev/null 2>&1; then
  python3 - <<'PY'
import json
print(json.dumps({
  "ok": False,
  "error": "maximize_window_failed_before_read",
  "hint": "请手动将大象窗口放大后重试"
}, ensure_ascii=False))
PY
  exit 1
fi

JS_FILE="$(mktemp -t daxiang-summary-send.XXXXXX.js)"
trap 'rm -f "$JS_FILE"' EXIT

python3 - "$RECEIVER" "$TIME_LABEL" > "$JS_FILE" <<'PY'
import json
import sys
receiver = sys.argv[1]
time_label = sys.argv[2]
print(r'''
await (async () => {
  const receiver = RECEIVER_PLACEHOLDER;
  const timeLabel = TIME_LABEL_PLACEHOLDER;
  const app = "cn.neixin.pc";
  const { sky } = await import("@oai/sky");

  function parseIdx(line) {
    const m = String(line || "").match(/^\s*(\d+)/);
    return m ? parseInt(m[1], 10) : null;
  }

  function normalizeText(line) {
    return String(line || "")
      .replace(/^\s*\d+\s+/, "")
      .replace(/^(文本|text|container|按钮|未加标签的图片)\s+/, "")
      .replace(/\[[^\]]*链接[^\]]*\]/g, "")
      .replace(/https?:\/\/\S+/g, "链接")
      .replace(/[\uE000-\uF8FF]/g, "")
      .replace(/\s+/g, " ")
      .trim();
  }

  function shouldIgnore(text) {
    if (!text) return true;
    if (/^\d{1,2}:\d{2}$/.test(text)) return true;
    if (/^\d+$/.test(text)) return true;
    if (/^(全部|@我|单聊|群聊|稍后|消息|通讯录|日历|工作台|更多|发送|说点什么\.\.\.|container|文本|text)$/.test(text)) return true;
    if (/^(Code代码仓库|Raptor-P[0-3]告警|Talos发布推送|审批|学城|移动HR)$/.test(text)) return true;
    if (/大象消息汇总|未读概览|重点消息|【代码 \/ PR】|【告警】|【发布 \/ 部署】|【审批 \/ 待办】|【提醒】|【群聊未读】/.test(text)) return true;
    if (/Command \+ Enter/.test(text)) return true;
    return false;
  }

  function shorten(text, max = 150) {
    const value = String(text || "").trim();
    return value.length > max ? `${value.slice(0, max)}…` : value;
  }

  function uniq(list) {
    const seen = new Set();
    const out = [];
    for (const item of list) {
      const key = item.replace(/\s+/g, " ").trim();
      if (!key || seen.has(key)) continue;
      seen.add(key);
      out.push(item);
    }
    return out;
  }

  function extractVisibleMessages(axText) {
    const allLines = axText.split("\n");
    const leftListLines = allLines.filter(line => {
      const idx = parseIdx(line);
      return idx !== null && idx >= 80 && idx < 240;
    });
    const lines = leftListLines.length > 20 ? leftListLines : allLines;
    const cards = [];
    let current = null;

    function isConversationName(text) {
      if (!text || shouldIgnore(text)) return false;
      if (/^\[\s*\d+条\s*\]$/.test(text)) return false;
      if (/^(\d+条未读|未读\s*\d+)$/.test(text)) return false;
      if (/^(系统邀请|江志伟加入|朱晓燕在|今天工作辛苦|磊哥|\[P[0-3]\]|Talos 2\.0|\[卡片\]|\[P)/.test(text)) return false;
      if (text.length > 40) return false;
      return true;
    }

    function finishCard() {
      if (!current || !current.name || !current.unread) return;
      const parts = [current.unread];
      if (current.preview) parts.push(current.preview);
      cards.push(`${current.name}：${parts.join("；")}`);
    }

    for (const line of lines) {
      if (!/(文本|text|container)/.test(line)) continue;
      const text = normalizeText(line);
      const isContainer = /\bcontainer\b/.test(line);
      const isTime = /^\d{1,2}:\d{2}$/.test(text);
      const unread = text.match(/^\[\s*(\d+)条\s*\]$/)?.[1];
      const plainUnread = text.match(/^(\d+)$/)?.[1];

      if (isContainer && isConversationName(text)) {
        finishCard();
        current = { name: text, unread: "", preview: "" };
        continue;
      }

      if (!current) continue;
      if (unread || (plainUnread && !current.unread)) {
        current.unread = `${unread || plainUnread}条未读`;
        continue;
      }
      if (shouldIgnore(text)) continue;
      if (isTime) continue;
      if (text === current.name) continue;
      if (!current.preview && /(未读|@你|@马世磊|P[0-3]|告警|恢复正常|故障|审批|Pull request|PR|Talos|发布|部署|打卡|消息助手|磊哥|先走了|加入了群聊|个群有新消息|工作流|Automan|xgpt|测试|开发|^.{2,30}：)/.test(text)) {
        current.preview = text;
      }
    }
    finishCard();
    return uniq(cards).slice(0, 80);
  }
  /** 点击消息列表上方的「未读」Tab（AX 可能为 按钮/text/文本 未读，末尾可有未读数角标） */
  async function clickUnreadTab(stateText) {
    const lines = stateText.split("\n");
    const tabLine = lines.find(l => /^\s*\d+\s+(按钮|text|文本)\s+未读/.test(l));
    if (!tabLine) return { clicked: false };
    const idx = parseIdx(tabLine);
    await sky.click({ app, element_index: idx });
    await new Promise(r => setTimeout(r, 800));
    return { clicked: true, idx };
  }

  async function clickAllTab(stateText) {
    const lines = stateText.split("\n");
    const tabLine = lines.find(l => /^\s*\d+\s+(按钮|text|文本)\s+全部/.test(l));
    if (!tabLine) return { clicked: false };
    const idx = parseIdx(tabLine);
    await sky.click({ app, element_index: idx });
    await new Promise(r => setTimeout(r, 800));
    return { clicked: true, idx };
  }

  /** 从未读列表解析：会话名、未读条数、可点击 idx */
  function parseUnreadConversations(axText) {
    const allLines = axText.split("\n");
    const leftListLines = allLines.filter(line => {
      const idx = parseIdx(line);
      return idx !== null && idx >= 80 && idx < 240;
    });
    const lines = leftListLines.length > 20 ? leftListLines : allLines;
    const convs = [];
    let current = null;

    function nameOk(text) {
      if (!text || shouldIgnore(text)) return false;
      if (/^\[\s*\d+条\s*\]$/.test(text)) return false;
      if (/^(\d+条未读|未读\s*\d+)$/.test(text)) return false;
      if (text.length > 40) return false;
      return true;
    }

    for (const line of lines) {
      if (!/(文本|text|container)/.test(line)) continue;
      const idx = parseIdx(line);
      const text = normalizeText(line);
      const isContainer = /\bcontainer\b/.test(line);
      const bracketUnread = text.match(/^\[\s*(\d+)条\s*\]$/)?.[1];
      const textUnread =
        text.match(/^(\d+)条未读$/)?.[1] || text.match(/^未读\s*(\d+)$/)?.[1];
      const plainUnread = text.match(/^(\d+)$/)?.[1];

      if (isContainer && nameOk(text)) {
        if (current && current.idx) convs.push(current);
        current = { name: text, unread: 0, idx, preview: "" };
        continue;
      }
      if (!current) continue;
      if (bracketUnread) current.unread = parseInt(bracketUnread, 10);
      else if (textUnread) current.unread = parseInt(textUnread, 10);
      else if (plainUnread && current.unread === 0) current.unread = parseInt(plainUnread, 10);
      else if (shouldIgnore(text)) continue;
      else if (!current.preview && text !== current.name && !/^\d{1,2}:\d{2}$/.test(text)) current.preview = text;
    }
    if (current && current.idx) convs.push(current);
    return convs.filter(c => c.unread > 0);
  }

  /** 从当前会话聊天区提取最近 limit 条消息 */
  function extractChatMessages(axText, limit, conversationName) {
    const allLines = axText.split("\n");
    const inputLine = allLines.find(l => /文本输入区/.test(l) && /说点什么/.test(l));
    const inputIdx = inputLine ? parseIdx(inputLine) : 99999;
    const titleLine = allLines.find(l => {
      const idx = parseIdx(l);
      return idx !== null && idx < inputIdx && new RegExp(`\\b(文本|text)\\s+${conversationName.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}$`).test(l);
    });
    const startIdx = titleLine ? parseIdx(titleLine) : 240;
    const messages = [];
    for (const line of allLines) {
      const idx = parseIdx(line);
      if (idx === null || idx <= startIdx || idx >= inputIdx) continue;
      if (!/(文本|text|文本栏)/.test(line)) continue;
      const text = normalizeText(line);
      if (shouldIgnore(text)) continue;
      if (/^\d{1,2}:\d{2}$/.test(text)) continue;
      if (text === conversationName) continue;
      if (text.length < 2) continue;
      messages.push(text);
    }
    return uniq(messages).slice(-Math.max(1, limit));
  }

  /** 未读 Tab + 逐会话打开，合并列表预览与聊天正文 */
  async function collectUnreadItems(initialText) {
    const unreadTab = await clickUnreadTab(initialText);
    if (!unreadTab.clicked) {
      return { ok: false, error: "unread_tab_not_found", items: [] };
    }
    let s = await sky.get_app_state({ app, disableDiff: true });
    let items = [];

    const MAX_CHATS = 10;
    let drilled = 0;
    const visited = new Set();
    const unreadConversationNames = new Set(parseUnreadConversations(s.text).map(c => c.name));
    for (let round = 0; round < MAX_CHATS; round++) {
      s = await sky.get_app_state({ app, disableDiff: true });
      await clickUnreadTab(s.text);
      await new Promise(r => setTimeout(r, 500));
      s = await sky.get_app_state({ app, disableDiff: true });
      const convs = parseUnreadConversations(s.text).filter(c => !visited.has(c.name));
      const conv = convs[0];
      if (!conv || !conv.unread || !conv.idx) break;
      visited.add(conv.name);

      await sky.click({ app, element_index: conv.idx });
      await new Promise(r => setTimeout(r, 900));
      const chatState = await sky.get_app_state({ app, disableDiff: true });
      const n = Math.min(conv.unread, 20);
      const chatMessages = extractChatMessages(chatState.text, n, conv.name);
      const effectiveMessages = chatMessages.length ? chatMessages : (conv.preview ? [conv.preview] : []);
      const preview = effectiveMessages.slice(-1)[0] || "";
      items.push(preview ? `${conv.name}：${conv.unread}条未读；${preview}` : `${conv.name}：${conv.unread}条未读`);
      drilled += 1;
    }
    return { ok: true, items: uniq(items), drilledChats: drilled, unreadConversationCount: unreadConversationNames.size };
  }

  function boldSource(text) {
    const value = String(text || "").trim();
    const idx = value.indexOf("：");
    if (idx <= 0) return value;
    const source = value.slice(0, idx).trim();
    const rest = value.slice(idx + 1).trim();
    if (!source || source.startsWith("**")) return value;
    if (source.length > 40) return value;
    return `**${source}**：${rest}`;
  }

  function dedupeBySource(items) {
    const seen = new Set();
    const out = [];
    for (const item of items) {
      const formatted = formatItem(item);
      const source = formatted.split("：")[0]?.trim() || formatted;
      if (!source || seen.has(source)) continue;
      seen.add(source);
      out.push(item);
    }
    return out;
  }

  function formatItem(text) {
    let value = String(text || "").trim();
    value = value.replace(/^(container|文本|text)：/, "");

    const prTitle = value.match(/Pull request\s*\[标\s*题\]\s*([^\[]+)/);
    if (prTitle) {
      const time = value.match(/\[时\s*间\]\s*([^\[]+)/)?.[1]?.trim();
      const source = value.match(/\[来源分支\]\s*([^\[]+)/)?.[1]?.trim();
      const target = value.match(/\[目标分支\]\s*([^\[]+)/)?.[1]?.trim();
      return `Code PR：${prTitle[1].trim()}${time ? `；时间 ${time}` : ""}${source ? `；${source} -> ${target || "目标分支"}` : ""}`;
    }

    const talos = value.match(/Talos[^：]*发布\s*-\s*([^ ]+).*?项目：([^ ]+)/);
    if (talos) return `Talos 发布：项目 ${talos[2]}，状态 ${talos[1]}`;

    const approval = value.match(/待你审批.*?申请人：([^ ]+).*?审批类型：([^ ]+).*?项目：([^ )]+\)?)/);
    if (approval) return `待审批：申请人 ${approval[1]}，类型 ${approval[2]}，项目 ${approval[3]}`;

    const alert = value.match(/\[(P[0-3])\].*?\[(故障|恢复正常)\].*?项目:\s*([^\]]+)/);
    if (alert) return `${alert[1]}${alert[2]}：${alert[3].replace(/^\[链接\]/, "")}`;

    value = value
      .replace(/^\[卡片\]\s*/, "")
      .replace(/\s*-{5,}.*$/, "")
      .replace(/\s+详情：.*$/, "")
      .replace(/\s+\[链\s*接\].*$/, "")
      .replace(/\s+Link：.*$/, "")
      .trim();

    return value;
  }

  function unreadOverview(items) {
    const joined = items.join("\n");
    const unread = uniq(joined.match(/未读\s*\d+/g) || []);
    const counts = uniq([...joined.matchAll(/(\d+)条未读/g)].map(m => `${m[1]}条`));
    const parts = [];
    if (unread.length) parts.push(`未读标记：${unread.join("、")}`);
    if (counts.length) parts.push(`会话未读：${counts.slice(0, 8).join("、")}`);
    return parts.length ? parts.join("；") : "未检测到带数字的未读会话；小红点会话已忽略";
  }

  function buildSummary(items) {
    let body = `【大象消息汇总｜${timeLabel}】\n\n未读概览：${unreadOverview(items)}\n`;
    if (!items.length) return body.trim();

    const rows = dedupeBySource(items).map(x => shorten(boldSource(formatItem(x)), 150));
    if (!rows.length) return body.trim();

    const separator = "------------------------------------------------";
    body += `\n\n${rows.map(x => `- ${x}`).join(`\n${separator}\n`)}`;
    return body.trim();
  }

  const s = await sky.get_app_state({ app, disableDiff: true });
  if (/Secondary Actions: Cancel/.test(s.text) && /发送\s*Markdown\s*消息/.test(s.text) && !/文本输入区|消息/.test(s.text)) {
    nodeRepl.write(JSON.stringify({ ok: false, error: "markdown_menu_open", hint: "当前大象停留在发送 Markdown 消息弹层，请先手动点击弹层外区域或选择取消，回到正常聊天窗口后重试" }));
  } else if (!/Window: "大象"|App: 大象|消息/.test(s.text)) {
    nodeRepl.write(JSON.stringify({ ok: false, error: "daxiang_not_ready", hint: "请先打开大象桌面客户端" }));
  } else {
    const collected = await collectUnreadItems(s.text);
    if (!collected.ok) {
      nodeRepl.write(JSON.stringify({
        ok: false,
        error: collected.error,
        hint: "请手动点击消息列表上方的「未读」Tab 后重试",
        itemCount: collected.items.length
      }));
      return;
    }
    const items = collected.items;
    const drilledChats = collected.drilledChats || 0;
    const unreadConversationCount = collected.unreadConversationCount || 0;
    const summary = buildSummary(items);

    // 下钻多个会话后界面可能变化，发送前重新激活并尽量放大窗口
    const { execFileSync } = await import("node:child_process");
    const daxiangApp = "/Applications/大象.app";
    try {
      execFileSync("/usr/bin/open", [daxiangApp]);
    } catch (_) {
      try { execFileSync("/usr/bin/open", ["-b", "cn.neixin.pc"]); } catch (_) {}
    }
    await new Promise(r => setTimeout(r, 300));
    const maximizeScript = `tell application "System Events"
  set daxiangProc to missing value
  try
    set daxiangProc to first application process whose bundle identifier is "cn.neixin.pc"
  end try
  if daxiangProc is missing value then
    if exists process "大象" then set daxiangProc to process "大象"
  end if
  if daxiangProc is missing value then error "daxiang process not found"
  set frontmost of daxiangProc to true
  tell daxiangProc
    set position of window 1 to {0, 33}
    set size of window 1 to {1512, 850}
  end tell
end tell`;
    let maximizeError = null;
    try {
      execFileSync("/usr/bin/osascript", ["-e", maximizeScript]);
    } catch (maxErr) {
      maximizeError = String(maxErr);
    }
    await new Promise(r => setTimeout(r, 1000));

    let sendState = await sky.get_app_state({ app, disableDiff: true });
    if (maximizeError && !/文本输入区.*说点什么|消息/.test(sendState.text)) {
      nodeRepl.write(JSON.stringify({ ok: false, error: "maximize_window_failed_before_send", hint: "请手动将大象窗口放大后重试", detail: maximizeError }));
      return;
    }
    await clickAllTab(sendState.text);
    sendState = await sky.get_app_state({ app, disableDiff: true });
    const receiverLine = sendState.text.split("\n").find(l => l.includes(`container ${receiver}`))
      || sendState.text.split("\n").find(l => l.includes(`文本 ${receiver}`));
    if (!receiverLine) {
      nodeRepl.write(JSON.stringify({ ok: false, error: "receiver_not_found", receiver, itemCount: items.length, summary }));
    } else {
      const receiverIdx = parseIdx(receiverLine);
      await sky.click({ app, element_index: receiverIdx });
      await new Promise(r => setTimeout(r, 1000));

      const latestBeforeMarkdown = await sky.get_app_state({ app, disableDiff: true });
      const latestLines = latestBeforeMarkdown.text.split("\n");
      const inputLine = latestLines.find(l => /文本输入区/.test(l) && /说点什么/.test(l));
      const inputIdx = inputLine ? parseIdx(inputLine) : null;
      const markdownButtonLine = inputIdx === null ? null : latestLines.filter(l => {
        const idx = parseIdx(l);
        return idx !== null && idx < inputIdx && idx >= inputIdx - 120 && /^\s*\d+\s+按钮\s+/.test(l);
      }).pop();

      if (!markdownButtonLine) {
        const markdownPreview = latestLines.filter(l => /Markdown|Mark|发送|按钮|文本输入区/.test(l)).slice(-120);
        nodeRepl.write(JSON.stringify({ ok: false, error: "markdown_button_not_found_after_maximize", receiver, receiverIdx, itemCount: items.length, inputIdx, markdownPreview, summary }));
        return;
      }

      const markdownIdx = parseIdx(markdownButtonLine);
      await sky.click({ app, element_index: markdownIdx });
      await new Promise(r => setTimeout(r, 800));

      let editorState = await sky.get_app_state({ app, disableDiff: true });
      let editorLines = editorState.text.split("\n");
      const markdownMenuLine = editorLines.find(l => /发送\s*Markdown\s*消息/.test(l));
      if (markdownMenuLine && !/Markdown编辑器/.test(editorState.text)) {
        await sky.click({ app, element_index: parseIdx(markdownMenuLine) });
        await new Promise(r => setTimeout(r, 800));
        editorState = await sky.get_app_state({ app, disableDiff: true });
        editorLines = editorState.text.split("\n");
      }
      const markdownInputLine = editorLines.find(l => /文本输入区/.test(l) && /请输入内容/.test(l));
      if (!markdownInputLine) {
        nodeRepl.write(JSON.stringify({ ok: false, error: "markdown_input_not_found", receiver, receiverIdx, markdownIdx, itemCount: items.length, summary, editorPreview: editorState.text.slice(0, 1000) }));
      } else {
        const markdownInputIdx = parseIdx(markdownInputLine);
        await sky.set_value({ app, element_index: markdownInputIdx, value: summary });
        await new Promise(r => setTimeout(r, 500));

        const filledState = await sky.get_app_state({ app, disableDiff: true });
        const sendLine = filledState.text.split("\n").find(l => /^\s*\d+\s+按钮\s+发送/.test(l));
        const hasContent = /大象消息汇总|未读概览/.test(filledState.text);
        const hasReceiver = filledState.text.includes(receiver);
        if (!sendLine || !hasContent || !hasReceiver) {
          nodeRepl.write(JSON.stringify({ ok: false, error: "markdown_editor_not_ready", receiver, receiverIdx, markdownIdx, markdownInputIdx, itemCount: items.length, hasSend: !!sendLine, hasContent, hasReceiver, summary, editorPreview: filledState.text.slice(0, 1000) }));
        } else {
          const sendIdx = parseIdx(sendLine);
          await sky.click({ app, element_index: sendIdx });
          await new Promise(r => setTimeout(r, 1200));
          const s4 = await sky.get_app_state({ app, disableDiff: true });
          nodeRepl.write(JSON.stringify({
            ok: true,
            receiver,
            receiverIdx,
            markdownIdx,
            markdownInputIdx,
            sendIdx,
            itemCount: items.length,
            drilledChats,
            unreadConversationCount,
            sentLikely: /大象消息汇总|未读概览/.test(s4.text),
            summary
          }));
        }
      }
    }
  }
})()
'''.replace('RECEIVER_PLACEHOLDER', json.dumps(receiver, ensure_ascii=False)).replace('TIME_LABEL_PLACEHOLDER', json.dumps(time_label, ensure_ascii=False)))
PY

bash "$SKILL_ROOT/scripts/exec.sh" -t 90000 -f "$JS_FILE"
