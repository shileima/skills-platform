#!/usr/bin/env bash
# 修复迭代：清空 canvas 业务节点 → 重新粘贴（不新建工作流）

set -euo pipefail

CLIPBOARD_FILE="${1:-}"
if [ -z "$CLIPBOARD_FILE" ] || [ ! -f "$CLIPBOARD_FILE" ]; then
  echo "usage: $0 <clipboard-payload.txt>" >&2
  exit 2
fi

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> 清空 canvas 业务节点"
CLEAR_OUT=$(bash "$SKILL_DIR/scripts/clear-canvas-nodes.sh" | tail -1)
echo "$CLEAR_OUT"

CLEAR_OK=$(echo "$CLEAR_OUT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('ok', False))" 2>/dev/null || echo "false")
if [ "$CLEAR_OK" != "True" ] && [ "$CLEAR_OK" != "true" ]; then
  echo "warn: 清空未完全成功，仍尝试粘贴" >&2
fi

echo "==> 重新粘贴节点"
PASTE_OUT=$(bash "$SKILL_DIR/scripts/paste-workflow.sh" "$CLIPBOARD_FILE" | tail -1)
echo "$PASTE_OUT"
