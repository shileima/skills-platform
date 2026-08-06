#!/usr/bin/env bash
# 京东 × 淘宝比价 · 一键预热脚本
# 用法：bash scripts/compare.sh "<商品关键词>"
#
# 本脚本只负责：
# 1. 定位并启动 cua-router-basic daemon
# 2. 做 Chrome 预检（Playwright 冲突自动处理）
# 3. 打印 SKILL_ROOT / QUERY / URLS 供 Agent 后续 exec.sh 内联脚本使用
#
# 复杂的 AX 解析、登录轮询、字段抽取交给 Agent 在 SKILL.md 里编排的
# `bash "$SKILL_ROOT/scripts/exec.sh"` 内联 JS 完成。

set -euo pipefail

QUERY="${1:-}"
if [ -z "$QUERY" ]; then
  echo "用法：bash scripts/compare.sh \"<商品关键词>\"" >&2
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
    echo "找不到 cua-router-basic 技能，请先安装。参考：" >&2
    echo "  curl -fsSL https://raw.githubusercontent.com/shileima/cua-router-basic/main/scripts/install-remote.sh | bash" >&2
    exit 1
  fi
  printf '%s\n' "$root"
}

url_encode() {
  # POSIX percent-encode（保留 unreserved + 空格转 %20）
  python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1], safe=""))' "$1"
}

SKILL_ROOT="$(resolve_cua_root)"
export CUA_ROUTER_CHROME_PREFLIGHT="${CUA_ROUTER_CHROME_PREFLIGHT:-auto}"

bash "$SKILL_ROOT/scripts/daemon.sh" start >/dev/null
bash "$SKILL_ROOT/scripts/exec.sh" 'nodeRepl.write("ok")' >/dev/null

ENCODED="$(url_encode "$QUERY")"
JD_URL="https://search.jd.com/Search?keyword=${ENCODED}&enc=utf-8"
TB_URL="https://s.taobao.com/search?q=${ENCODED}"

cat <<EOF
{
  "ok": true,
  "skillRoot": "$SKILL_ROOT",
  "query": "$QUERY",
  "urls": {
    "jd": "$JD_URL",
    "taobao": "$TB_URL",
    "jdHome": "https://www.jd.com/",
    "taobaoHome": "https://www.taobao.com/"
  },
  "hint": "Agent 现在可以调用 exec.sh 内联 JS 采集两个平台的详情页字段。登录敏感处使用 waitLogin({ platform: 'jd'|'tb' }) 每 10s 轮询。"
}
EOF
