#!/usr/bin/env bash
set -euo pipefail

PROMPT="${1:-北京降雨分时}"
# 优先 osascript 写剪贴板，避免部分环境下 pbcopy 失败
/usr/bin/osascript -e "set the clipboard to $(python3 -c 'import json,sys; print(json.dumps(sys.argv[1], ensure_ascii=False))' "$PROMPT")" 2>/dev/null \
  || printf '%s' "$PROMPT" | /usr/bin/pbcopy
PROMPT_JSON="$(python3 -c 'import json, sys; print(json.dumps(sys.argv[1], ensure_ascii=False))' "$PROMPT")"

resolve_cua_root() {
  local candidate
  local -a candidates=()
  [ -n "${CUA_ROUTER_INSTALL_DIR:-}" ] && candidates+=("$CUA_ROUTER_INSTALL_DIR")
  candidates+=("$HOME/.automan/claude-code-agents/cua-agent/skills/cua-router-basic")
  candidates+=("$HOME/.automan/skills/cua-router-basic")
  candidates+=("$HOME/.cursor/skills/cua-router-basic")
  for candidate in "${candidates[@]}"; do
    if [ -f "$candidate/SKILL.md" ] && [ -x "$candidate/scripts/exec.sh" ]; then
      printf '%s' "$candidate"
      return 0
    fi
  done
  echo "找不到 cua-router-basic。请先安装 cua-router-basic，或设置 CUA_ROUTER_INSTALL_DIR。" >&2
  return 1
}

CUA_ROOT="$(resolve_cua_root)"
/usr/bin/open -a CatDesk

CODE="$(cat <<'JS'
const app = "com.catpaw.cowork";
const prompt = __PROMPT_JSON__;
const wait = (ms) => new Promise(resolve => setTimeout(resolve, ms));
const log = [];

async function get(label) {
  const s = await ax.get(app, { refresh: true });
  log.push({ phase: label, textLen: s.text.length });
  return s;
}

async function waitFor(label, predicate, timeoutMs = 8000, intervalMs = 300) {
  const started = Date.now();
  let last;
  while (Date.now() - started < timeoutMs) {
    last = await get(label);
    if (predicate(last)) return last;
    await wait(intervalMs);
  }
  throw new Error(`${label} 超时: ${JSON.stringify(ax.linesMatching(last?.text ?? "", /新任务|聊天输入框|Max|LongCat|发送|请输入内容后再发送|Lite|Pro/, { limit: 40 }))}`);
}

function firstIdx(text, patterns, label) {
  for (const pattern of patterns) {
    const idx = ax.findIdx(text, ...pattern);
    if (idx != null) {
      log.push({ target: label, element_index: idx, pattern });
      return idx;
    }
  }
  const hints = ax.linesMatching(text, /新任务|聊天输入框|Max|LongCat|发送|请输入内容后再发送|Lite|Pro/, { limit: 60 });
  throw new Error(`未找到${label}: ${JSON.stringify(hints)}`);
}

function settableInputIdx(text) {
  const line = text.split("\n").find(l => l.includes("文本输入区") && l.includes("settable") && l.includes("聊天输入框"));
  const match = line && line.trim().match(/^(\d+)/);
  if (!match) return null;
  const idx = Number(match[1]);
  log.push({ target: "可写聊天输入框", element_index: idx });
  return idx;
}

let s = await waitFor("CatDesk 主界面", current => current.text.includes("新任务") && current.text.includes("聊天输入框"));

let idx = firstIdx(s.text, [["按钮", "新任务"], ["新任务"]], "新任务按钮");
await sky.click({ app, element_index: idx });
s = await waitFor("点击新任务后审视", current => current.text.includes("聊天输入框"));

// 已是 Max 且聊天框可用时跳过模型切换
const skipModelPick = /弹出式按钮 Max|文本 Max\b/.test(s.text) && s.text.includes("聊天输入框");
if (!skipModelPick) {
  const modelButton =
    ax.findIdx(s.text, "弹出式按钮", "Max") ??
    ax.findIdx(s.text, "弹出式按钮", "LongCat") ??
    ax.findIdx(s.text, "弹出式按钮", "Pro");
  if (modelButton == null) {
    throw new Error("未找到模型弹出式按钮");
  }
  log.push({ target: "模型弹出式按钮", element_index: modelButton });
  await sky.click({ app, element_index: modelButton });

  s = await waitFor(
    "打开模型列表后审视",
    current => current.text.includes("Lite") && current.text.includes("Pro") && current.text.includes("Max"),
    6000,
    300,
  );
  const maxIdx = ax.findIdx(s.text, "Max", "适合超复杂任务") ?? ax.findIdx(s.text, "Max");
  if (maxIdx == null) {
    throw new Error("模型列表中未找到 Max");
  }
  log.push({ target: "Max 模型选项", element_index: maxIdx });
  await sky.click({ app, element_index: maxIdx });
  await wait(300);
  await sky.press_key({ app, key: "Escape" });
}

s = await waitFor(
  "模型选择后/chat 就绪",
  current =>
    current.text.includes("聊天输入框") &&
    current.text.includes("settable") &&
    !current.text.includes("适合超复杂任务"),
  8000,
  300,
);

idx = settableInputIdx(s.text) ?? firstIdx(s.text, [["聊天输入框"]], "聊天输入框");
await sky.click({ app, element_index: idx });
await wait(200);
await sky.press_key({ app, key: "Command+a" });
await wait(100);
await sky.press_key({ app, key: "Command+v" });

s = await waitFor("粘贴后审视", current => current.text.includes(prompt));

idx = firstIdx(s.text, [["按钮", "发送"], ["按钮", "请输入内容后再发送"]], "发送按钮");
await sky.click({ app, element_index: idx });

s = await waitFor(
  "发送后审视",
  current => current.text.includes(prompt) && /思考|回复|停止生成|重新生成|输入框清空/.test(current.text),
  10000,
  400,
);

nodeRepl.write(JSON.stringify({ ok: true, prompt, log }, null, 2));
JS
)"
CODE="${CODE/__PROMPT_JSON__/$PROMPT_JSON}"

bash "$CUA_ROOT/scripts/ensure-ready.sh" >/dev/null
bash "$CUA_ROOT/scripts/exec.sh" -t 120000 "$CODE"
