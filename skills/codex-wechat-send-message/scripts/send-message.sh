#!/usr/bin/env bash
# 微信桌面客户端：搜索联系人并发送消息（固化成功路径）
# 用法：send-message.sh "<联系人>" "<消息内容>"
# 测试：send-test-message.sh ["<消息>"] → 固定发给文件传输助手

set -euo pipefail

CONTACT="${1:-}"
MESSAGE="${2:-}"

if [ -z "$CONTACT" ] || [ -z "$MESSAGE" ]; then
  echo "Usage: $0 <contact> <message>" >&2
  echo 'Example: $0 "尹来春" "中午吃什么"' >&2
  echo 'Test:    bash ./scripts/send-test-message.sh "测试消息"' >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/wechat-common.sh
source "$SCRIPT_DIR/lib/wechat-common.sh"

SKILL_ROOT="$(wechat_resolve_cua_root)"
export CUA_ROUTER_RUNTIME_DIR="${CUA_ROUTER_RUNTIME_DIR:-$SKILL_ROOT/runtime}"
export CODEX_HOME="${CODEX_HOME:-$CUA_ROUTER_RUNTIME_DIR}"

echo "[wechat] ensure cua-router ready..."
bash "$SKILL_ROOT/scripts/daemon.sh" start >/dev/null 2>&1 || true
bash "$SKILL_ROOT/scripts/ensure-ready.sh" >/dev/null

wechat_run_send_message "$CONTACT" "$MESSAGE"
