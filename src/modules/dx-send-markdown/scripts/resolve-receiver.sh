#!/usr/bin/env bash
# Resolve dx 接收人：
#   1. 若显式传入非空姓名，直接返回；
#   2. 否则读取本地 automan 客户端登录人（~/Library/Preferences/automan/config.json.operator）；
#   3. 找不到时返回空串，由调用方决定报错或询问用户。
#
# 用法：
#   source "$(dirname "$0")/resolve-receiver.sh"
#   RECEIVER="$(resolve_dx_receiver "$USER_INPUT")"

resolve_dx_receiver() {
  local given="${1:-}"
  if [ -n "$given" ]; then
    printf '%s' "$given"
    return 0
  fi

  local config="${AUTOMAN_CONFIG_FILE:-${HOME}/Library/Preferences/automan/config.json}"
  if [ ! -f "$config" ]; then
    return 0
  fi

  python3 - "$config" <<'PY' 2>/dev/null || true
import json
import sys

try:
    with open(sys.argv[1], "r", encoding="utf-8") as f:
        data = json.load(f)
except Exception:
    sys.exit(0)

value = data.get("operator") or ""
if isinstance(value, str):
    sys.stdout.write(value.strip())
PY
}
