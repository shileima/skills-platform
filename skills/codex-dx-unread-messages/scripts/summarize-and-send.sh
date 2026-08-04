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

if ! osascript \
  -e 'tell application "大象" to activate' \
  -e 'delay 0.5' \
  -e 'tell application "System Events" to tell process "大象" to set position of window 1 to {0, 33}' \
  -e 'tell application "System Events" to tell process "大象" to set size of window 1 to {1512, 850}' >/dev/null 2>&1; then
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
      if (!current || !current.name) return;
      const parts = [];
      if (current.unread) parts.push(current.unread);
      if (current.preview) parts.push(current.preview);
      if (parts.length) cards.push(`${current.name}：${parts.join("；")}`);
    }

    for (const line of lines) {
      if (!/(文本|text|container)/.test(line)) continue;
      const text = normalizeText(line);
      if (shouldIgnore(text)) continue;

      const isContainer = /\bcontainer\b/.test(line);
      const isTime = /^\d{1,2}:\d{2}$/.test(text);
      const unread = text.match(/^\[\s*(\d+)条\s*\]$/)?.[1];

      if (isContainer && isConversationName(text)) {
        finishCard();
        current = { name: text, unread: "", preview: "" };
        continue;
      }

      if (!current) continue;
      if (isTime) continue;
      if (text === current.name) continue;
      if (unread) {
        current.unread = `${unread}条未读`;
        continue;
      }
      if (!current.preview && /(未读|@你|@马世磊|P[0-3]|告警|恢复正常|故障|审批|Pull request|PR|Talos|发布|部署|打卡|消息助手|磊哥|先走了|加入了群聊|个群有新消息|工作流|Automan|xgpt|测试|开发|^.{2,30}：)/.test(text)) {
        current.preview = text;
      }
    }
    finishCard();
    return uniq(cards).slice(0, 80);
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

  function pick(items, re, limit = 3, maxLen = 150) {
    return uniq(items.filter(x => re.test(x)).map(x => shorten(boldSource(formatItem(x)), maxLen))).slice(0, limit);
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
    return parts.length ? parts.join("；") : "未检测到明确未读数字，以当前可见近期消息为准";
  }

  function section(title, rows) {
    if (!rows.length) return "";
    const separator = "------------------------------------------------";
    return `\n【${title}】\n${rows.map(x => `- ${x}`).join(`\n${separator}\n`)}`;
  }

  function buildSummary(items) {
    const pr = pick(items, /Pull request|来源分支|目标分支|Code代码仓库/, 3, 170);
    const alerts = pick(items, /\[P[0-3]\]|P[0-3]|恢复正常|故障|错误总量|504|告警/, 4, 160);
    const deploys = pick(items, /Talos|部署成功|发布 - success|托管部署成功/, 4, 160);
    const approvals = pick(items, /待你审批|申请人|审批/, 3, 150);
    const reminders = pick(items, /今天工作辛苦|打卡|移动HR|学城/, 4, 120);
    const groups = pick(items, /\d+条未读|个群有新消息|加入了群聊|群/, 8, 120);

    let body = `【大象消息汇总｜${timeLabel}】\n\n未读概览：${unreadOverview(items)}\n`;
    body += section("代码 / PR", pr);
    body += section("告警", alerts);
    body += section("发布 / 部署", deploys);
    body += section("审批 / 待办", approvals);
    body += section("提醒", reminders);
    body += section("群聊未读", groups);

    if (!body.includes("- ")) {
      body += section("近期消息", items.slice(0, 8).map(x => shorten(formatItem(x), 130)));
    }
    return body.trim();
  }

  const s = await sky.get_app_state({ app, disableDiff: true });
  if (/Secondary Actions: Cancel/.test(s.text) && /发送\s*Markdown\s*消息/.test(s.text) && !/文本输入区|消息/.test(s.text)) {
    nodeRepl.write(JSON.stringify({ ok: false, error: "markdown_menu_open", hint: "当前大象停留在发送 Markdown 消息弹层，请先手动点击弹层外区域或选择取消，回到正常聊天窗口后重试" }));
  } else if (!/Window: "大象"|App: 大象|消息/.test(s.text)) {
    nodeRepl.write(JSON.stringify({ ok: false, error: "daxiang_not_ready", hint: "请先打开大象桌面客户端" }));
  } else {
    const items = extractVisibleMessages(s.text);
    const summary = buildSummary(items);

    const receiverLine = s.text.split("\n").find(l => l.includes(`container ${receiver}`))
      || s.text.split("\n").find(l => l.includes(`文本 ${receiver}`));
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
