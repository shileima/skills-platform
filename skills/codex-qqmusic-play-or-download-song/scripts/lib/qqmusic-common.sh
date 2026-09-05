#!/usr/bin/env bash
# QQ 音乐技能共享：进程名探测、窗口等待、更新弹框关闭。
set -euo pipefail

QQM_BUNDLE="${QQM_BUNDLE:-com.tencent.QQMusicMac}"
QQM_APP="${QQM_APP:-com.tencent.QQMusicMac}"
QQM_PROCESS_CANDIDATES=("QQMusic" "QQ音乐")

qqmusic_resolve_skill_root() {
  local root="${CUA_ROUTER_INSTALL_DIR:-${HOME}/.automan/claude-code-agents/cua-agent/skills/cua-router-basic}"
  if [ ! -f "$root/SKILL.md" ]; then
    root="${HOME}/.cursor/skills/cua-router-basic"
  fi
  if [ ! -f "$root/SKILL.md" ]; then
    echo "cua-router-basic not installed. Run its install-remote.sh first." >&2
    return 1
  fi
  printf '%s' "$root"
}

qqmusic_process_has_window() {
  local proc="$1"
  osascript -e "tell application \"System Events\"
    if exists process \"$proc\" then
      return (count of windows of process \"$proc\") > 0
    end if
    return false
  end tell" 2>/dev/null | grep -q true
}

qqmusic_wait_for_window() {
  local i proc
  for i in 1 2 3 4 5 6 7 8 10 12 15; do
    for proc in "${QQM_PROCESS_CANDIDATES[@]}"; do
      if qqmusic_process_has_window "$proc"; then
        printf '%s' "$proc"
        return 0
      fi
    done
    sleep 1
  done
  return 1
}

qqmusic_activate() {
  osascript -e "tell application id \"$QQM_BUNDLE\" to activate" >/dev/null 2>&1 || true
  sleep 1
}

# 顶栏全局搜索框中心（窗口相对坐标）。窗口变宽后固定 (438,40) 会点到会员中心。
qqmusic_search_box_center() {
  if [ ! -x /usr/bin/swift ]; then
    echo '{"x":438,"y":40,"text":"fallback"}'
    return 0
  fi
  /usr/bin/swift - <<'SWIFT' 2>/dev/null || echo '{"x":438,"y":40,"text":"fallback"}'
import Foundation
import AppKit
import ApplicationServices

let bundle = "com.tencent.QQMusicMac"
guard let runningApp = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundle }) else {
  print("{\"x\":438,\"y\":40,\"text\":\"no-app\"}")
  exit(0)
}
let app = AXUIElementCreateApplication(runningApp.processIdentifier)

func attr(_ el: AXUIElement, _ name: CFString) -> AnyObject? {
  var value: AnyObject?
  return AXUIElementCopyAttributeValue(el, name, &value) == .success ? value : nil
}
func str(_ el: AXUIElement, _ name: CFString) -> String { (attr(el, name) as? String) ?? "" }
func point(_ el: AXUIElement, _ name: CFString) -> CGPoint? {
  guard let value = attr(el, name), CFGetTypeID(value) == AXValueGetTypeID() else { return nil }
  var p = CGPoint.zero
  return AXValueGetValue(value as! AXValue, .cgPoint, &p) ? p : nil
}
func size(_ el: AXUIElement, _ name: CFString) -> CGSize? {
  guard let value = attr(el, name), CFGetTypeID(value) == AXValueGetTypeID() else { return nil }
  var s = CGSize.zero
  return AXValueGetValue(value as! AXValue, .cgSize, &s) ? s : nil
}
func children(_ el: AXUIElement) -> [AXUIElement] { (attr(el, kAXChildrenAttribute as CFString) as? [AXUIElement]) ?? [] }

func findSearch(_ el: AXUIElement) -> AXUIElement? {
  let role = str(el, kAXRoleAttribute as CFString)
  let desc = str(el, kAXDescriptionAttribute as CFString)
  let title = str(el, kAXTitleAttribute as CFString)
  if desc == "搜索", let sz = size(el, kAXSizeAttribute as CFString), sz.width > 80, sz.height > 16 {
    return el
  }
  if title == "搜索" && role.contains("Text"), let sz = size(el, kAXSizeAttribute as CFString), sz.width > 80 {
    return el
  }
  for child in children(el) {
    if let found = findSearch(child) { return found }
  }
  return nil
}

let roots = children(app)
guard let window = roots.first(where: { str($0, kAXRoleAttribute as CFString) == (kAXWindowRole as String) }),
      let wp = point(window, kAXPositionAttribute as CFString),
      let field = roots.compactMap({ findSearch($0) }).first,
      let fp = point(field, kAXPositionAttribute as CFString),
      let fs = size(field, kAXSizeAttribute as CFString) else {
  print("{\"x\":438,\"y\":40,\"text\":\"not-found\"}")
  exit(0)
}
let obj: [String: Any] = [
  "text": "ax-search-center",
  "x": Int(fp.x - wp.x + fs.width / 2),
  "y": Int(fp.y - wp.y + fs.height / 2),
  "w": Int(fs.width),
  "h": Int(fs.height)
]
print(String(data: try JSONSerialization.data(withJSONObject: obj, options: []), encoding: .utf8)!)
SWIFT
}

# 关闭 QQ 音乐启动时的版本更新弹框（AX 按钮「以后提醒」/「稍后更新」等）。
qqmusic_dismiss_update_dialog() {
  local skill_root="$1"
  local lib_dir out js_file
  lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  js_file="$lib_dir/dismiss-update-dialog.js"
  [ -f "$js_file" ] || return 0

  out=$(bash "$skill_root/scripts/exec.sh" -t 45000 -f "$js_file" 2>&1) || {
    echo "[qqmusic] warning: failed to inspect/dismiss update dialog" >&2
    return 0
  }

  printf '%s\n' "$out" | python3 -c 'import json,sys,re; s=sys.stdin.read(); m=re.findall(r"\{.*\}", s, re.S); d=json.loads(m[-1]) if m else {}; print(json.dumps(d, ensure_ascii=False))' 2>/dev/null || true
}
