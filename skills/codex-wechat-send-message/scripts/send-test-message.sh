#!/usr/bin/env bash
# 测试专用：固定发给「文件传输助手」，不走侧栏搜索。
# 用法：send-test-message.sh ["<消息内容>"]

set -euo pipefail

MESSAGE="${1:-测试消息}"
CONTACT="${WECHAT_TEST_CONTACT:-文件传输助手}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

exec bash "$SCRIPT_DIR/send-message.sh" "$CONTACT" "$MESSAGE"
