#!/usr/bin/env bash
# 每个 /exec 步骤批次前激活 Chrome 并确保有可见窗口

set -euo pipefail

osascript <<'AS'
tell application "Google Chrome"
  activate
  if (count of windows) = 0 then make new window
end tell
delay 1
tell application "System Events" to set frontmost of process "Google Chrome" to true
delay 1
AS
