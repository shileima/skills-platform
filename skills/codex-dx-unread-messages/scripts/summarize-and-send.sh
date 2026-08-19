#!/usr/bin/env bash
set -euo pipefail

RECEIVER="${1:-}"
TIME_LABEL="${2:-$(date '+%Y-%m-%d %H:%M左右')}"

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 定位 dx-send-markdown 模块（安装后在 skill 目录里；开发态回退到仓库 src/modules）
DX_MODULE_DIR=""
if [ -d "$SKILL_DIR/modules/dx-send-markdown" ]; then
  DX_MODULE_DIR="$SKILL_DIR/modules/dx-send-markdown"
elif [ -d "$SKILL_DIR/../../src/modules/dx-send-markdown" ]; then
  DX_MODULE_DIR="$(cd "$SKILL_DIR/../../src/modules/dx-send-markdown" && pwd)"
else
  echo '{"ok":false,"error":"dx-send-markdown module not found"}' >&2
  exit 1
fi

# shellcheck source=../../src/modules/dx-send-markdown/scripts/resolve-receiver.sh
source "$DX_MODULE_DIR/scripts/resolve-receiver.sh"
RECEIVER="$(resolve_dx_receiver "$RECEIVER")"

if [ -z "$RECEIVER" ]; then
  python3 - <<'PY'
import json
print(json.dumps({
  "ok": False,
  "error": "receiver_required",
  "hint": "未指定接收人，且未从 ~/Library/Preferences/automan/config.json 读取到 operator；请以 `bash summarize-and-send.sh <接收人>` 显式传入"
}, ensure_ascii=False))
PY
  exit 1
fi

SKILL_ROOT="${CUA_ROUTER_INSTALL_DIR:-${HOME}/.automan/claude-code-agents/cua-agent/skills/cua-router-basic}"
if [ ! -f "$SKILL_ROOT/SKILL.md" ]; then
  SKILL_ROOT="${HOME}/.cursor/skills/cua-router-basic"
fi
if [ ! -f "$SKILL_ROOT/SKILL.md" ]; then
  SKILL_ROOT="${HOME}/.automan/skills/cua-router-basic"
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

  // 本人身份标识：用于判断某条消息是否「与我有关」。
  // 由接收人姓名派生（去掉 (英文别名)、去掉尾部 DX 工号），额外补充第一人称提及。
  const SELF_TOKENS = (() => {
    const tokens = new Set();
    const raw = String(receiver || "").trim();
    if (raw) {
      tokens.add(raw);
      const noAlias = raw.replace(/\(.*\)$/, "").trim();
      if (noAlias) tokens.add(noAlias);
      const noDx = noAlias.replace(/DX\d+$/i, "").trim();
      if (noDx) tokens.add(noDx);
    }
    return [...tokens].filter(t => t && t.length >= 2);
  })();

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
    if (/^(学城)$/.test(text)) return true;
    if (/大象消息汇总|未读概览|智能概括|✨|重点消息|【代码 \/ PR】|【告警】|【发布 \/ 部署】|【审批 \/ 待办】|【提醒】|【群聊未读】/.test(text)) return true;
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

      // 未读 Tab 下会话常合并为单行：`会话名 ：N条未读；最新预览`
      const single = text.match(/^(.+?)\s*：\s*(\d+)条未读[；;]?\s*(.*)$/);
      if (single && idx !== null && single[1].trim().length <= 40 && nameOk(single[1].trim())) {
        if (current && current.idx) convs.push(current);
        current = null;
        convs.push({
          name: single[1].trim(),
          unread: parseInt(single[2], 10),
          idx,
          preview: single[3].trim()
        });
        continue;
      }

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

  /**
   * 从当前会话聊天区提取可见消息，并返回可用于滚动的节点。
   * 大象聊天区节点结构：每条消息气泡通常由「头像图片 + 发送者名文本」开头，
   * 随后是正文文本节点与业务图片节点（`未加标签的图片 /...@640w...`）。
   * 图片消息不是文本节点，必须显式识别为 `[图片]`，否则会被整体丢弃。
   */
  function extractChatSnapshot(axText, conversationName) {
    const allLines = axText.split("\n");
    const inputLine = allLines.find(l => /文本输入区/.test(l) && /说点什么/.test(l));
    const inputIdx = inputLine ? parseIdx(inputLine) : 99999;
    const escapedName = conversationName.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const titleLine = allLines.filter(l => {
      const idx = parseIdx(l);
      return idx !== null && idx < inputIdx && new RegExp(`(文本|text)\\s+${escapedName}\\s*$`).test(l);
    }).pop();
    const startIdx = titleLine ? parseIdx(titleLine) : 240;

    const scrollCandidates = [];
    const bubbles = [];
    let sender = "";
    let expectSenderName = false;
    let newBubble = true;

    // 头像：`*_200_200` 结尾或纯 UUID；业务图片：含 `@数字w` 或 `w=数字` 尺寸参数；
    // 群缩略 `?t=THUMB` 与工具栏图标 `*.png` 一律忽略。
    const isAvatar = p => /_200_200\b/.test(p) || /^\/[0-9a-f]{8}-[0-9a-f-]+$/i.test(p);
    const isBizImage = p => /@\d+w/.test(p) || /[?&]w=\d+/.test(p);
    const isThumb = p => /\?t=THUMB/i.test(p);
    const isIcon = p => /\.(png|jpe?g|gif|svg)\b/i.test(p);

    function pushText(text) {
      const last = bubbles[bubbles.length - 1];
      if (newBubble || !last || last.isImage || last.sender !== sender) {
        bubbles.push({ sender, text, isImage: false });
      } else {
        last.text += " " + text;
      }
      newBubble = false;
    }
    function pushImage() {
      bubbles.push({ sender, text: "[图片]", isImage: true });
      newBubble = true;
    }

    for (const line of allLines) {
      const idx = parseIdx(line);
      if (idx === null || idx <= startIdx || idx >= inputIdx) continue;
      if (/(container|group|列表|内容列表|滚动区域|scroll area)/i.test(line)) {
        scrollCandidates.push(idx);
        continue;
      }
      const imgMatch = line.match(/未加标签的图片\s+(\S+)/);
      if (imgMatch) {
        const path = imgMatch[1];
        if (isIcon(path) || isThumb(path)) continue;
        if (isAvatar(path)) { expectSenderName = true; newBubble = true; continue; }
        if (isBizImage(path)) { pushImage(); scrollCandidates.push(idx); continue; }
        continue;
      }
      if (!/(文本|text|文本栏)/.test(line)) continue;
      const text = normalizeText(line);
      if (!text) continue;
      // 时间戳（HH:MM / MM-DD / MM-DD HH:MM）作为气泡分隔
      if (/^\d{1,2}:\d{2}$/.test(text) || /^\d{1,2}-\d{1,2}(\s+\d{1,2}:\d{2})?$/.test(text)) { newBubble = true; continue; }
      // 头像之后紧跟的短文本即发送者名
      if (expectSenderName) {
        expectSenderName = false;
        // 发送人姓名可能带上英文别名（如 `吴冰莹(Ingrid Wu)`），放宽到 30 字
        if (text.length <= 30 && !/：$/.test(text) && !/[，。？！,!?]/.test(text)) { sender = text; newBubble = true; continue; }
      }
      if (/^.{1,30}：$/.test(text)) continue; // 引用块的发送者名（以全角冒号结尾）
      if (/^(应删除|全部改正 无需纠错 设置|Markdown 预览视图|智能概括)$/.test(text)) continue;
      if (/^\d+条回复$/.test(text)) continue;
      // 邀请类系统消息一律忽略：`邀请xxx加入了群聊`、`xx加入了群聊`、`新成员入群可查看所有的历史消息` 等
      if (/邀请.{0,40}加入了群聊/.test(text)) continue;
      if (/新成员入群可查看.*历史消息/.test(text)) continue;
      if (/^.{1,30}加入了群聊$/.test(text)) continue;
      if (text === conversationName) continue;
      if (shouldIgnore(text)) continue;
      pushText(text);
      scrollCandidates.push(idx);
    }

    const messages = bubbles
      .map(b => {
        const content = String(b.text || "").trim();
        if (!content) return "";
        // 群聊/多人会话消息带发送人时，用 **发送人** 标注；单聊无发送人时直出正文
        return b.sender ? `**${b.sender}**：${content}` : content;
      })
      .filter(message => {
        if (!message) return false;
        // 二次过滤：极少数邀请类消息在 bubble 拼接后才成完整句
        if (/邀请.{0,40}加入了群聊/.test(message)) return false;
        if (/新成员入群可查看.*历史消息/.test(message)) return false;
        if (/^\*\*[^*]+\*\*：.{0,30}加入了群聊$/.test(message)) return false;
        return true;
      });

    return { messages, scrollCandidates: [...new Set(scrollCandidates)] };
  }

  /** 将更早的可见窗口拼到已有消息前，仅消除两个相邻窗口的重叠部分。 */
  function prependOverlappingWindow(existing, older) {
    if (!existing.length) return older.slice();
    if (!older.length) return existing.slice();
    const maxOverlap = Math.min(existing.length, older.length);
    let overlap = 0;
    for (let size = maxOverlap; size > 0; size--) {
      const olderTail = older.slice(-size);
      const existingHead = existing.slice(0, size);
      if (olderTail.every((message, idx) => message === existingHead[idx])) {
        overlap = size;
        break;
      }
    }
    return older.concat(existing.slice(overlap));
  }

  /**
   * 大象聊天区采用虚拟列表，首次打开通常只暴露最后一条消息。
   * 从底部开始逐页向上滚动并合并相邻窗口，直到收集到最近 N 条或没有更多内容。
   */
  async function collectRecentChatMessages(initialState, limit, conversationName) {
    let merged = [];
    let state = initialState;
    let previousSignature = "";
    let unchangedScrolls = 0;
    const maxScrolls = Math.min(30, Math.max(6, limit * 2 + 2));

    for (let attempt = 0; attempt <= maxScrolls; attempt++) {
      const snapshot = extractChatSnapshot(state.text, conversationName);
      const signature = snapshot.messages.join("\u0001");
      if (signature && signature !== previousSignature) {
        merged = prependOverlappingWindow(merged, snapshot.messages);
        unchangedScrolls = 0;
      } else if (attempt > 0) {
        unchangedScrolls += 1;
      }

      if (merged.length >= limit || !snapshot.scrollCandidates.length || unchangedScrolls >= 3) {
        return merged.slice(-limit);
      }

      previousSignature = signature;
      const candidateOrder = attempt % 3;
      const candidatePosition = candidateOrder === 0
        ? 0
        : candidateOrder === 1
          ? Math.floor((snapshot.scrollCandidates.length - 1) / 2)
          : snapshot.scrollCandidates.length - 1;
      const scrollIdx = snapshot.scrollCandidates[candidatePosition];
      try {
        await sky.scroll({ app, element_index: scrollIdx, direction: "up", pages: 2 });
      } catch (_) {
        unchangedScrolls += 1;
      }
      await new Promise(r => setTimeout(r, 900));
      state = await sky.get_app_state({ app, disableDiff: true });
    }

    return merged.slice(-limit);
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
      const chatMessages = await collectRecentChatMessages(chatState, n, conv.name);
      const effectiveMessages = chatMessages.length ? chatMessages : (conv.preview ? [conv.preview] : []);
      const preview = effectiveMessages.slice(-n).map(message => shorten(message, 120)).join("；");
      items.push(preview ? `${conv.name}：${conv.unread}条未读；${preview}` : `${conv.name}：${conv.unread}条未读`);
      drilled += 1;
    }
    return { ok: true, items: uniq(items), drilledChats: drilled, unreadConversationCount: unreadConversationNames.size };
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

  function splitMessageList(text) {
    return uniq(String(text || "")
      .split(/[；;]+/)
      .map(x => x.trim())
      .filter(x => x && x !== "-" && !shouldIgnore(x)));
  }

  function formatConversationBlock(text) {
    const value = formatItem(text);
    const match = value.match(/^(.+?)：\s*(\d+)条未读(?:[；;]\s*(.*))?$/);
    if (match && match[1].trim().length <= 40) {
      const source = match[1].trim();
      const count = match[2];
      const messages = splitMessageList(match[3] || "").map(message => shorten(message, 120));
      if (!messages.length) return `**${source}**：${count}条未读`;
      // 会话标题使用无 bullet 的加粗行；具体消息使用顶层 `- ` 列表，避免二级列表被渲染成实心黑块
      return `**${source}**：${count}条未读\n\n${messages.map(message => `- ${message}`).join("\n")}`;
    }

    const idx = value.indexOf("：");
    if (idx > 0) {
      const source = value.slice(0, idx).trim();
      const rest = value.slice(idx + 1).trim();
      if (source && source.length <= 40 && rest) {
        return `**${source}**：\n\n- ${shorten(rest, 120)}`;
      }
    }
    return `- ${value}`;
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

  function stripMarkdownBold(text) {
    return String(text || "").replace(/\*\*([^*]+)\*\*/g, "$1").trim();
  }

  function parseConversationItems(items) {
    return items.map(item => {
      const formatted = formatItem(item);
      const match = formatted.match(/^(.+?)：\s*(\d+)条未读(?:[；;]\s*(.*))?$/);
      if (match && match[1].trim().length <= 40) {
        return {
          source: match[1].trim(),
          unread: parseInt(match[2], 10),
          messages: splitMessageList(match[3] || "")
        };
      }
      return { source: formatted, unread: 0, messages: [formatted] };
    });
  }

  function messageBody(message) {
    const plain = stripMarkdownBold(message);
    const idx = plain.indexOf("：");
    if (idx > 0 && idx <= 30 && !/\d{4}-\d{2}-\d{2}/.test(plain.slice(0, idx))) {
      return plain.slice(idx + 1).trim();
    }
    return plain;
  }

  function extractReleasePlanSummary(body) {
    const m = String(body || "").match(
      /系统于(\d{4}-\d{2}-\d{2})\s*(\d{2}:\d{2}).*?自动创建(.+?上线计划).*?值班QA为([^，,]+).*?预计上线时间(\d{4}-\d{2}-\d{2})\s*(\d{2}:\d{2}:\d{2})/
    );
    if (!m) return null;
    return `系统于${m[1]} ${m[2]}自动创建${m[3]}，值班QA为${m[4]}，预计上线时间${m[5]} ${m[6]}`;
  }

  function extractSender(message) {
    const plain = stripMarkdownBold(message);
    const m = plain.match(/^([^：]{1,30})：/);
    if (m && !/\d{4}-\d{2}-\d{2}/.test(m[1])) return m[1].trim();
    return "";
  }

  function extractMentions(text) {
    const mentions = [];
    const re = /@([\u4e00-\u9fa5A-Za-z0-9_.-]{1,24})/g;
    let match;
    while ((match = re.exec(String(text || ""))) !== null) {
      const name = match[1];
      if (/^(我|你|全部|我$)/.test(name)) continue;
      if (!mentions.includes(name)) mentions.push(name);
    }
    return mentions;
  }

  function atMention(name) {
    const value = String(name || "").trim();
    if (!value) return "";
    return value.startsWith("@") ? value : `@${value}`;
  }

  function receiverCoreName(name) {
    return String(name || "").replace(/\(.*\)$/, "").replace(/DX\d+$/i, "").trim();
  }

  function enrichSummaryWithPeople(message, summary) {
    const plain = stripMarkdownBold(message);
    const sender = extractSender(message);
    const body = messageBody(message);
    let text = String(summary || body).trim();

    if (sender && !text.includes(atMention(sender)) && !new RegExp(`\\b${sender}\\b`).test(text)) {
      text = `${atMention(sender)} ${text}`;
    }

    for (const name of extractMentions(plain)) {
      const tagged = atMention(name);
      if (body.includes(tagged) && !text.includes(tagged)) {
        text = text.replace(name, tagged);
      }
    }

    text = text.replace(/值班QA为([\u4e00-\u9fa5A-Za-z0-9_.-]{1,24})/g, (_, qa) => `值班QA为${atMention(qa)}`);
    text = text.replace(/申请人[：: ]?([\u4e00-\u9fa5A-Za-z0-9_.-]{1,24})/g, (_, person) => `申请人${atMention(person)}`);

    return shorten(text, 200);
  }

  // 返回消息中某个人名匹配到的本人标准姓名（未命中返回空串）
  function matchedSelfToken(name) {
    const value = String(name || "").replace(/^@/, "").trim();
    if (!value || value.length < 2) return "";
    return SELF_TOKENS.find(token => value === token || value.includes(token) || token.includes(value)) || "";
  }

  // 判断消息中的某个人名是否指向本人
  function isSelfName(name) {
    return matchedSelfToken(name) !== "";
  }

  /**
   * 智能判断该消息/讨论是否与本人有关，并给出具体原因。
   * 命中多个原因时合并；都不命中返回「无」。
   */
  function detectRelatedToMe(message) {
    const plain = stripMarkdownBold(message);
    const reasons = [];

    // 1. 直接被 @你 / @我
    if (/@\s*(你|我)\b|@\s*(你|我)[^\u4e00-\u9fa5A-Za-z0-9]/.test(plain) || /@(你|我)$/.test(plain)) {
      reasons.push("被 @你 直接提及");
    }

    // 2. 消息里 @提及 命中本人姓名
    for (const name of extractMentions(plain)) {
      const self = matchedSelfToken(name);
      if (self) {
        reasons.push(`被 ${atMention(self)} 提及`);
        break;
      }
    }

    // 3. 正文（非 @）中出现本人姓名
    if (!reasons.length) {
      for (const token of SELF_TOKENS) {
        if (plain.includes(token)) {
          reasons.push(`内容提及 ${atMention(token)}`);
          break;
        }
      }
    }

    // 4. 本人是本次值班 QA
    const qa = plain.match(/值班QA为@?([\u4e00-\u9fa5A-Za-z0-9_.\-()]{1,24})/)?.[1];
    if (qa && isSelfName(qa)) reasons.push("你是本次值班QA");

    // 5. 审批 / 指派 / 跟进等指向本人的动作
    if (/待你审批|等你审批|需你审批/.test(plain)) reasons.push("待你审批");
    if (/(转给|指派给|交给|分配给|派给)\s*@?(你|我)/.test(plain)) reasons.push("已转交给你处理");
    if (/@?(你|我)\s*(来|去)?(处理|负责|跟进|确认|核实|回复|看[下一]?|排查|评估)/.test(plain)) {
      reasons.push("需你跟进处理");
    }
    if (/(请|麻烦|辛苦|拜托)\s*@?(你|我)/.test(plain)) reasons.push("有人请你协助");

    // 6. @提及命中本人后又被要求处理（转给@本人处理）
    for (const name of extractMentions(plain)) {
      if (isSelfName(name) && /(处理|负责|跟进|确认|回复|转给)/.test(plain)) {
        reasons.push("被点名跟进");
        break;
      }
    }

    return reasons.length ? uniq(reasons).join("；") : "无";
  }

  function detectDiscussionTag(body) {
    if (/询问|请问|知道|有没有|吗[？?]/.test(body)) return "话题引入";
    if (/表示|认为|觉得|建议|心得|经验|主要用于/.test(body)) return "工具使用观点";
    if (/通知|公告|提醒|请关注/.test(body)) return "通知";
    return "群聊讨论";
  }

  function deriveDiscussionCategory(source, body, plain) {
    const quoted = body.match(/[“"「]([^”"」]{2,20})[”"」]/)?.[1];
    if (quoted) return `${quoted}讨论`;
    const keyword = plain.match(/([\u4e00-\u9fa5A-Za-z0-9_-]{2,12})(营销|工具|发布|上线|故障|审批)/)?.[0];
    if (keyword) return `${keyword}讨论`;
    return `${source}讨论`;
  }

  function classifyResult(message, source, partial) {
    return {
      category: partial.category,
      tag: partial.tag,
      summary: enrichSummaryWithPeople(message, partial.summary),
      relatedToMe: detectRelatedToMe(message)
    };
  }

  function detectIterationName(text) {
    return text.match(/(ED\/FSD日常迭代--\d+)/)?.[1]
      || text.match(/(\d{2}\.\d{2}-[^；;，,\s]{2,30})/)?.[1]
      || null;
  }

  function detectTag(body, source, categoryHint, plainMessage) {
    const text = `${plainMessage || body} ${source}`;
    if (/自动创建.*上线计划/.test(text)) return "自动创建上线计划";
    if (/Talos|开始发布|发布成功/.test(text)) return "Talos 发布";
    if (/Pull request|PR|合并请求/.test(text)) return "PR 通知";
    if (/\[P[0-3]\]/.test(text)) return text.match(/\[(P[0-3])\]/)?.[1] + (text.includes("恢复") ? "恢复" : "故障");
    if (/待你审批|审批/.test(text)) return "审批待办";
    if (/部署/.test(text)) return "部署通知";
    if (/交付/.test(text)) return "交付通知";
    if (/上线/.test(text)) return "上线通知";
    if (/打卡|HR/.test(text)) return "提醒";
    if (categoryHint && categoryHint.length <= 16) return categoryHint;
    if (source.length <= 16) return source;
    return "消息";
  }

  function classifyMessage(message, source) {
    const plain = stripMarkdownBold(message);
    const body = messageBody(message);
    const full = `${source} ${plain}`;
    const sender = extractSender(message);

    const releasePlan = extractReleasePlanSummary(body);
    if (releasePlan || /自动创建.*上线计划/.test(body)) {
      return classifyResult(message, source, {
        category: "上线计划创建与值班QA安排",
        tag: "自动创建上线计划",
        summary: releasePlan || shorten(body, 200)
      });
    }

    const iteration = detectIterationName(full);
    if (iteration) {
      let theme = "相关通知";
      if (/交付|部署|发布|Talos/.test(full)) theme = "交付与部署";
      else if (/QA|值班/.test(full)) theme = "值班与QA安排";
      return classifyResult(message, source, {
        category: `${iteration}${theme}`,
        tag: detectTag(body, source, iteration, plain),
        summary: shorten(body, 200)
      });
    }

    if (/\[P[0-3]\]/.test(plain) || /告警|故障|恢复正常/.test(plain)) {
      return classifyResult(message, source, {
        category: "故障与告警",
        tag: detectTag(body, source, null, plain),
        summary: shorten(plain.replace(/\[链接\]/g, "").trim(), 200)
      });
    }

    if (/Pull request|PR|Code PR|合并请求/.test(plain)) {
      return classifyResult(message, source, {
        category: "代码评审与合并",
        tag: "PR 通知",
        summary: shorten(body, 200)
      });
    }

    if (/Talos|发布成功|开始发布/.test(plain)) {
      return classifyResult(message, source, {
        category: "发布与部署",
        tag: "Talos 发布",
        summary: shorten(body, 200)
      });
    }

    if (/待你审批|审批/.test(plain)) {
      return classifyResult(message, source, {
        category: "审批待办",
        tag: "审批待办",
        summary: shorten(body, 200)
      });
    }

    if (/打卡|HR|提醒/.test(plain)) {
      return classifyResult(message, source, {
        category: "提醒与通知",
        tag: "提醒",
        summary: shorten(body, 200)
      });
    }

    if (sender || extractMentions(plain).length) {
      return classifyResult(message, source, {
        category: deriveDiscussionCategory(source, body, plain),
        tag: detectDiscussionTag(body),
        summary: shorten(body, 200)
      });
    }

    return classifyResult(message, source, {
      category: source,
      tag: detectTag(body, source, source, plain),
      summary: shorten(plain, 200)
    });
  }

  function mergeRelatedToMe(entries) {
    const reasons = [];
    for (const entry of entries) {
      if (!entry.relatedToMe || entry.relatedToMe === "无") continue;
      for (const part of entry.relatedToMe.split(/[；、]/)) {
        const value = part.trim();
        if (value && value !== "无" && !reasons.includes(value)) reasons.push(value);
      }
    }
    return reasons.length ? reasons.join("；") : "无";
  }

  // 渲染单条原始未读消息：群聊消息把发送人加粗，单聊无发送人时直出正文
  function renderRawMessage(message) {
    const sender = extractSender(message);
    const body = shorten(messageBody(message), 120);
    if (!body) return "";
    if (sender) return `- **${sender}**：${body}`;
    return `- ${body}`;
  }

  function buildIntelligentSummary(items) {
    const convs = parseConversationItems(items);
    const sections = [];

    for (const conv of convs) {
      const entries = [];
      const rawLines = [];
      const seenRaw = new Set();
      for (const msg of conv.messages) {
        const { tag, summary, relatedToMe } = classifyMessage(msg, conv.source);
        if (summary && !shouldIgnore(summary)) {
          const key = `${tag}|${summary}`;
          if (!entries.some(entry => `${entry.tag}|${entry.summary}` === key)) {
            entries.push({ tag, summary, relatedToMe });
          }
        }
        const raw = renderRawMessage(msg);
        if (raw && !seenRaw.has(raw)) {
          seenRaw.add(raw);
          rawLines.push(raw);
        }
      }
      if (!entries.length && !rawLines.length) continue;
      sections.push({
        source: conv.source,
        unread: conv.unread || rawLines.length,
        entries,
        rawLines
      });
    }

    if (!sections.length) return "";

    const separator = "------------------------------------------------";
    const lines = ["✨ 智能概括", ""];
    let sectionNo = 1;
    for (const section of sections) {
      if (sectionNo > 1) {
        lines.push(separator);
        lines.push("");
      }
      // 主题标题直接标注未读条数：`N. 会话名 X条未读`
      lines.push(`${sectionNo}. ${section.source} ${section.unread}条未读`);
      for (const { tag, summary } of section.entries) {
        lines.push(`- **[${tag}]** ${summary}`);
      }
      for (const raw of section.rawLines) {
        lines.push(raw);
      }
      lines.push(`- 与我有关：${mergeRelatedToMe(section.entries)}`);
      lines.push("");
      sectionNo += 1;
    }
    return lines.join("\n").trim();
  }

  function buildSummary(items) {
    // 仅保留「✨ 智能概括」一个区块，不再输出「未读概览」及各会话未读明细，避免同一条消息重复
    let body = `【大象消息汇总｜${timeLabel}】\n`;
    const intelligent = buildIntelligentSummary(items);
    if (intelligent) {
      body += `\n${intelligent}`;
    }
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

    nodeRepl.write(JSON.stringify({
      ok: true,
      receiver,
      itemCount: items.length,
      drilledChats,
      unreadConversationCount,
      summary
    }));
  }
})()
'''.replace('RECEIVER_PLACEHOLDER', json.dumps(receiver, ensure_ascii=False)).replace('TIME_LABEL_PLACEHOLDER', json.dumps(time_label, ensure_ascii=False)))
PY

FETCH_RESULT="$(bash "$SKILL_ROOT/scripts/exec.sh" -t 90000 -f "$JS_FILE")"
echo "$FETCH_RESULT"
LAST_LINE="$(printf '%s\n' "$FETCH_RESULT" | tail -n 1)"

python3 -c 'import json,sys; d=json.loads(sys.argv[1]); sys.exit(0 if d.get("ok") else 1)' "$LAST_LINE" || exit 1

SUMMARY="$(python3 -c 'import json,sys; print(json.loads(sys.stdin.read())["summary"])' <<< "$LAST_LINE")"

printf '%s' "$SUMMARY" | bash "$DX_MODULE_DIR/scripts/send-markdown.sh" \
  "$RECEIVER" --all-tab --marker "大象消息汇总|智能概括"
