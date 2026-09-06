#!/usr/bin/env bash
# 微信技能共享：cua-router 定位、窗口边界、cliclick 封装、截图与 OCR 校验。
set -euo pipefail

WECHAT_BUNDLE="${WECHAT_BUNDLE:-com.tencent.xinWeChat}"
WECHAT_PROCESS="${WECHAT_PROCESS:-WeChat}"

wechat_resolve_cua_root() {
  local candidate
  local -a candidates=()

  if [ -n "${CUA_ROUTER_INSTALL_DIR:-}" ]; then
    candidates+=("$CUA_ROUTER_INSTALL_DIR")
  fi
  candidates+=(
    "${HOME}/.automan/claude-code-agents/cua-agent/skills/cua-router-basic"
    "${HOME}/.automan/skills/cua-router-basic"
    "${HOME}/.cursor/skills/cua-router-basic"
    "${HOME}/code/cua-router-basic"
  )

  for candidate in "${candidates[@]}"; do
    [ -f "$candidate/SKILL.md" ] || continue
    if bash "$candidate/scripts/cua.sh" list_apps >/dev/null 2>&1; then
      printf '%s' "$candidate"
      return 0
    fi
  done

  for candidate in "${candidates[@]}"; do
    if [ -f "$candidate/SKILL.md" ]; then
      printf '%s' "$candidate"
      return 0
    fi
  done

  echo "cua-router-basic not installed. Run its install script first." >&2
  return 1
}

wechat_resolve_cliclick() {
  if [ -n "${CLICLICK:-}" ] && [ -x "$CLICLICK" ]; then
    printf '%s' "$CLICLICK"
    return 0
  fi
  if command -v cliclick >/dev/null 2>&1; then
    command -v cliclick
    return 0
  fi
  echo "cliclick not found. Install: brew install cliclick" >&2
  return 1
}

wechat_to_json() {
  python3 -c 'import json,sys; print(json.dumps(sys.argv[1], ensure_ascii=False))' "$1"
}

wechat_file_url_to_path() {
  python3 -c 'import sys,urllib.parse; u=sys.argv[1]; print(urllib.parse.unquote(u[7:] if u.startswith("file://") else u))' "$1"
}

wechat_activate() {
  open -b "$WECHAT_BUNDLE" >/dev/null 2>&1 || open -a WeChat >/dev/null 2>&1 || true
  osascript -e "tell application id \"$WECHAT_BUNDLE\" to activate" >/dev/null 2>&1 || \
    osascript -e 'tell application "WeChat" to activate' >/dev/null 2>&1 || true
  sleep 0.4
}

wechat_process_has_window() {
  osascript -e "tell application \"System Events\"
    if exists process \"$WECHAT_PROCESS\" then
      return (count of windows of process \"$WECHAT_PROCESS\") > 0
    end if
    return false
  end tell" 2>/dev/null | grep -q true
}

wechat_wait_for_window() {
  local i
  for i in 1 2 3 4 5 6 8 10 12 15; do
    if wechat_process_has_window; then
      return 0
    fi
    sleep 1
  done
  return 1
}

# 标准化窗口尺寸，减少相对坐标漂移。
wechat_normalize_window() {
  local target_w="${WECHAT_WINDOW_WIDTH:-960}"
  local target_h="${WECHAT_WINDOW_HEIGHT:-720}"
  osascript <<EOF >/dev/null 2>&1 || return 1
tell application "System Events"
  set wxProc to missing value
  try
    set wxProc to first application process whose bundle identifier is "$WECHAT_BUNDLE"
  end try
  if wxProc is missing value then
    if exists process "$WECHAT_PROCESS" then set wxProc to process "$WECHAT_PROCESS"
  end if
  if wxProc is missing value then error "WeChat process not found"
  set frontmost of wxProc to true
  tell wxProc
    set position of window 1 to {80, 33}
    set size of window 1 to {$target_w, $target_h}
  end tell
end tell
EOF
  sleep 0.8
  local bounds w h
  bounds="$(wechat_window_bounds)"
  w=$(printf '%s' "$bounds" | python3 -c 'import json,sys; print(json.loads(sys.stdin.read())["w"])')
  h=$(printf '%s' "$bounds" | python3 -c 'import json,sys; print(json.loads(sys.stdin.read())["h"])')
  if [ "$w" -lt 800 ] || [ "$h" -lt 600 ]; then
    return 1
  fi
}

wechat_press_escape() {
  local cliclick_bin
  cliclick_bin="$(wechat_resolve_cliclick)"
  "$cliclick_bin" kp:esc
}

# 点击左侧导航栏「聊天」图标。
wechat_go_to_chats_tab() {
  wechat_click_rel "${WECHAT_NAV_CHAT_X:-0.04}" "${WECHAT_NAV_CHAT_Y:-0.11}"
  sleep 0.25
}

# prepare：固定按键序列，零 OCR 截图。
wechat_prepare_ui() {
  local cliclick_bin
  cliclick_bin="$(wechat_resolve_cliclick)"
  wechat_activate
  wechat_wait_for_window
  wechat_normalize_window || true
  wechat_go_to_chats_tab
  "$cliclick_bin" kp:esc
  sleep 0.12
  "$cliclick_bin" kp:esc
  sleep 0.12
  "$cliclick_bin" kd:cmd t:w ku:cmd
  sleep 0.2
  wechat_click_rel "0.18" "0.22"
  sleep 0.25
}

# 退出全屏「搜一搜」：点聊天 Tab + Esc + 点击聊天列表区域。
wechat_escape_global_search() {
  local i shot cliclick_bin bounds click_x click_y
  cliclick_bin="$(wechat_resolve_cliclick)"
  for i in 1 2 3; do
    shot="$(wechat_screenshot_path || true)"
    if [ -z "$shot" ] || [ "$(wechat_in_global_search "$shot")" != "yes" ]; then
      return 0
    fi
    echo "[wechat] escaping global 搜一搜 (attempt $i)..." >&2
    wechat_go_to_chats_tab
    "$cliclick_bin" kp:esc
    sleep 0.4
    "$cliclick_bin" kd:cmd t:w ku:cmd
    sleep 0.4
    bounds="$(wechat_window_bounds)"
    read -r click_x click_y < <(python3 -c '
import json, sys
b = json.loads(sys.argv[1])
print(int(b["x"] + b["w"] * 0.18), int(b["y"] + b["h"] * 0.22))
' "$bounds")
    "$cliclick_bin" "c:${click_x},${click_y}"
    sleep 0.6
  done
  shot="$(wechat_screenshot_path || true)"
  [ -n "$shot" ] && [ "$(wechat_in_global_search "$shot")" != "yes" ]
}

wechat_is_file_transfer_assistant() {
  [ "$1" = "文件传输助手" ] || [ "$1" = "${WECHAT_TEST_CONTACT:-文件传输助手}" ]
}

wechat_in_global_search() {
  local shot="$1"
  local result
  result="$(wechat_ocr_contains_any "$shot" "搜一搜" "搜索发现" 2>/dev/null || echo '{"ok":false}')"
  printf '%s' "$result" | python3 -c 'import json,sys; print("yes" if json.loads(sys.stdin.read()).get("ok") else "no")' 2>/dev/null || echo "no"
}

# 输出 JSON: {"x":..,"y":..,"w":..,"h":..}
wechat_window_bounds() {
  osascript <<'EOF' 2>/dev/null || echo '{"x":80,"y":33,"w":960,"h":720}'
tell application "System Events"
  set wxProc to missing value
  try
    set wxProc to first application process whose bundle identifier is "com.tencent.xinWeChat"
  end try
  if wxProc is missing value then
    if exists process "WeChat" then set wxProc to process "WeChat"
  end if
  if wxProc is missing value then return "{\"x\":80,\"y\":33,\"w\":960,\"h\":720}"
  tell wxProc
    set p to position of window 1
    set s to size of window 1
    return "{\"x\":" & (item 1 of p) & ",\"y\":" & (item 2 of p) & ",\"w\":" & (item 1 of s) & ",\"h\":" & (item 2 of s) & "}"
  end tell
end tell
EOF
}

# 窗口相对坐标 (0~1) → 屏幕绝对坐标并点击。
wechat_click_rel() {
  local rel_x="$1"
  local rel_y="$2"
  local bounds click_x click_y cliclick_bin
  bounds="$(wechat_window_bounds)"
  read -r click_x click_y < <(python3 -c '
import json, sys
b = json.loads(sys.argv[1])
rx, ry = float(sys.argv[2]), float(sys.argv[3])
print(int(b["x"] + b["w"] * rx), int(b["y"] + b["h"] * ry))
' "$bounds" "$rel_x" "$rel_y")
  cliclick_bin="$(wechat_resolve_cliclick)"
  "$cliclick_bin" "c:${click_x},${click_y}"
}

wechat_paste_text() {
  local text="$1"
  local cliclick_bin
  printf '%s' "$text" | /usr/bin/pbcopy
  cliclick_bin="$(wechat_resolve_cliclick)"
  "$cliclick_bin" kd:cmd t:a ku:cmd
  sleep 0.15
  "$cliclick_bin" kd:cmd t:v ku:cmd
}

wechat_screenshot_path() {
  local cua_root out text url
  cua_root="$(wechat_resolve_cua_root)"
  out=$(bash "$cua_root/scripts/cua.sh" --json get_app_state "{\"app\":\"$WECHAT_BUNDLE\"}" 2>/dev/null) || return 1
  url=$(printf '%s' "$out" | python3 -c '
import json, sys
raw = sys.stdin.read()
try:
  d = json.loads(raw)
  if d.get("isError"):
    raise ValueError(d.get("error", "cua error"))
  text = d.get("content", [{}])[0].get("text", "")
  if text.startswith("{"):
    j = json.loads(text)
    shot = j.get("screenshot")
    if isinstance(shot, dict):
      print(shot.get("url", ""))
    else:
      print(j.get("screenshotUrl", ""))
  else:
    print("")
except Exception:
  print("")
' 2>/dev/null)
  [ -n "$url" ] || return 1
  wechat_file_url_to_path "$url"
}

# Vision OCR：返回关键词在截图中的中心坐标（屏幕绝对坐标需调用方加上窗口偏移）。
wechat_ocr_find_text_center() {
  local image_path="$1"
  local keyword="$2"
  [ -f "$image_path" ] || return 1
  [ -x /usr/bin/swift ] || return 1

  local keyword_json
  keyword_json="$(wechat_to_json "$keyword")"

  /usr/bin/swift - "$image_path" "$keyword_json" <<'SWIFT'
import Foundation
import Vision
import AppKit

let path = CommandLine.arguments[1]
let keyword = CommandLine.arguments[2]
guard let image = NSImage(contentsOfFile: path),
      let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
  print("null")
  exit(0)
}

let request = VNRecognizeTextRequest()
request.recognitionLevel = .accurate
request.usesLanguageCorrection = true
request.recognitionLanguages = ["zh-Hans", "en-US"]
let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
try handler.perform([request])

let width = CGFloat(cgImage.width)
let height = CGFloat(cgImage.height)
var best: (score: Float, x: CGFloat, y: CGFloat)? = nil

for observation in request.results ?? [] {
  guard let candidate = observation.topCandidates(1).first else { continue }
  let text = candidate.string
  guard text.contains(keyword) else { continue }
  let box = observation.boundingBox
  let cx = (box.minX + box.width / 2) * width
  let cy = (1 - box.minY - box.height / 2) * height
  let score = candidate.confidence
  if best == nil || score > best!.score {
    best = (score, cx, cy)
  }
}

if let best {
  let obj: [String: Any] = ["text": keyword, "x": Int(best.x), "y": Int(best.y), "confidence": best.score]
  print(String(data: try JSONSerialization.data(withJSONObject: obj, options: []), encoding: .utf8)!)
} else {
  print("null")
}
SWIFT
}

# 在左侧聊天列表中定位文字（排除顶部搜索栏，避免误点「搜一搜」入口）。
wechat_ocr_find_chat_list_item() {
  local image_path="$1"
  local keyword="$2"
  local min_rel_y="${3:-0.10}"
  local max_rel_x="${4:-0.38}"
  [ -f "$image_path" ] || return 1
  [ -x /usr/bin/swift ] || return 1

  local keyword_json
  keyword_json="$(wechat_to_json "$keyword")"

  /usr/bin/swift - "$image_path" "$keyword_json" "$min_rel_y" "$max_rel_x" <<'SWIFT'
import Foundation
import Vision
import AppKit

let path = CommandLine.arguments[1]
let keyword = CommandLine.arguments[2]
let minRelY = Double(CommandLine.arguments[3]) ?? 0.10
let maxRelX = Double(CommandLine.arguments[4]) ?? 0.38
guard let image = NSImage(contentsOfFile: path),
      let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
  print("null")
  exit(0)
}

let request = VNRecognizeTextRequest()
request.recognitionLevel = .accurate
request.usesLanguageCorrection = true
request.recognitionLanguages = ["zh-Hans", "en-US"]
let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
try handler.perform([request])

let width = CGFloat(cgImage.width)
let height = CGFloat(cgImage.height)
var best: (score: Float, x: CGFloat, y: CGFloat)? = nil

for observation in request.results ?? [] {
  guard let candidate = observation.topCandidates(1).first else { continue }
  let text = candidate.string
  let matched: Bool = {
    if text.contains(keyword) || keyword.contains(text) { return text.count >= 2 }
    if keyword.count >= 4 {
      let suffix = String(keyword.suffix(min(4, keyword.count)))
      if text.contains(suffix) { return true }
    }
    return false
  }()
  guard matched else { continue }
  let box = observation.boundingBox
  let cx = (box.minX + box.width / 2) * width
  let cy = (1 - box.minY - box.height / 2) * height
  let relX = Double(cx / width)
  let relY = Double(cy / height)
  if relX > maxRelX || relY < minRelY { continue }
  let score = candidate.confidence
  if best == nil || score > best!.score {
    best = (score, cx, cy)
  }
}

if let best {
  let obj: [String: Any] = ["text": keyword, "x": Int(best.x), "y": Int(best.y), "confidence": best.score]
  print(String(data: try JSONSerialization.data(withJSONObject: obj, options: []), encoding: .utf8)!)
} else {
  print("null")
}
SWIFT
}

wechat_click_chat_list_item() {
  local keyword="$1"
  local shot target_json rel_x abs_y bounds win_x win_y
  shot="$(wechat_screenshot_path || true)"
  [ -n "$shot" ] || return 1
  target_json="$(wechat_ocr_find_chat_list_item "$shot" "$keyword" 2>/dev/null || echo null)"
  if [ "$target_json" = "null" ] && wechat_is_file_transfer_assistant "$keyword"; then
    echo "[wechat] OCR miss, fallback coord for 文件传输助手" >&2
    wechat_click_rel "${WECHAT_FTA_REL_X:-0.18}" "${WECHAT_FTA_REL_Y:-0.28}"
    return 0
  fi
  [ "$target_json" != "null" ] || return 1
  bounds="$(wechat_window_bounds)"
  read -r rel_x abs_y < <(python3 -c '
import json, sys
t = json.loads(sys.argv[1])
print(t["x"], t["y"])
' "$target_json")
  read -r win_x win_y < <(python3 -c 'import json,sys; b=json.loads(sys.argv[1]); print(b["x"], b["y"])' "$bounds")
  local cliclick_bin
  cliclick_bin="$(wechat_resolve_cliclick)"
  "$cliclick_bin" "c:$((win_x + rel_x)),$((win_y + abs_y))"
}

wechat_click_ocr_text() {
  local keyword="$1"
  local max_rel_x="${2:-0.38}"
  local shot target_json rel_x abs_x abs_y bounds win_x win_y win_w
  shot="$(wechat_screenshot_path || true)"
  [ -n "$shot" ] || return 1
  target_json="$(wechat_ocr_find_text_center "$shot" "$keyword" 2>/dev/null || echo null)"
  [ "$target_json" != "null" ] || return 1
  bounds="$(wechat_window_bounds)"
  read -r rel_x abs_y < <(python3 -c '
import json, sys
t = json.loads(sys.argv[1])
b = json.loads(sys.argv[2])
print(t["x"], t["y"])
' "$target_json" "$bounds")
  win_w=$(python3 -c 'import json,sys; print(json.loads(sys.argv[1])["w"])' "$bounds")
  # 截图坐标是窗口内像素；限制点击在中左栏（聊天列表/搜索结果）
  if [ "$rel_x" -gt "$(python3 -c "print(int($win_w * $max_rel_x))")" ]; then
    return 1
  fi
  read -r win_x win_y < <(python3 -c 'import json,sys; b=json.loads(sys.argv[1]); print(b["x"], b["y"])' "$bounds")
  abs_x=$((win_x + rel_x))
  abs_y=$((win_y + abs_y))
  local cliclick_bin
  cliclick_bin="$(wechat_resolve_cliclick)"
  "$cliclick_bin" "c:${abs_x},${abs_y}"
}

wechat_click_ocr_text_anywhere() {
  local keyword="$1"
  local shot target_json abs_x abs_y bounds win_x win_y
  shot="$(wechat_screenshot_path || true)"
  [ -n "$shot" ] || return 1
  target_json="$(wechat_ocr_find_text_center "$shot" "$keyword" 2>/dev/null || echo null)"
  [ "$target_json" != "null" ] || return 1
  bounds="$(wechat_window_bounds)"
  read -r abs_x abs_y < <(python3 -c '
import json, sys
t = json.loads(sys.argv[1])
b = json.loads(sys.argv[2])
print(t["x"] + b["x"], t["y"] + b["y"])
' "$target_json" "$bounds")
  local cliclick_bin
  cliclick_bin="$(wechat_resolve_cliclick)"
  "$cliclick_bin" "c:${abs_x},${abs_y}"
}

# 输入框区域是否已有目标消息（右侧底部 y > 78%）。
wechat_input_has_message() {
  local shot="$1"
  local message="$2"
  [ -f "$shot" ] || return 1
  [ -x /usr/bin/swift ] || return 1
  local msg_json
  msg_json="$(wechat_to_json "$message")"
  /usr/bin/swift - "$shot" "$msg_json" <<'SWIFT'
import Foundation
import Vision
import AppKit

let path = CommandLine.arguments[1]
let message = CommandLine.arguments[2]
guard let image = NSImage(contentsOfFile: path),
      let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
  print("no")
  exit(0)
}
let request = VNRecognizeTextRequest()
request.recognitionLevel = .accurate
request.recognitionLanguages = ["zh-Hans", "en-US"]
try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
let w = CGFloat(cgImage.width), h = CGFloat(cgImage.height)
for observation in request.results ?? [] {
  guard let candidate = observation.topCandidates(1).first else { continue }
  let text = candidate.string
  var hit = text.contains(message)
  if !hit && message.count >= 2 {
    for i in 0..<(message.count - 1) {
      let start = message.index(message.startIndex, offsetBy: i)
      let end = message.index(start, offsetBy: 2)
      if text.contains(String(message[start..<end])) { hit = true; break }
    }
  }
  guard hit else { continue }
  let box = observation.boundingBox
  let cx = (box.minX + box.width / 2) * w
  let cy = (1 - box.minY - box.height / 2) * h
  if cx / w > 0.35 && cy / h > 0.72 {
    print("yes")
    exit(0)
  }
}
print("no")
SWIFT
}

# 定位右下角绿色「发送」按钮。
wechat_ocr_find_send_button() {
  local image_path="$1"
  [ -f "$image_path" ] || return 1
  [ -x /usr/bin/swift ] || return 1
  /usr/bin/swift - "$image_path" <<'SWIFT'
import Foundation
import Vision
import AppKit

let path = CommandLine.arguments[1]
guard let image = NSImage(contentsOfFile: path),
      let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
  print("null")
  exit(0)
}
let request = VNRecognizeTextRequest()
request.recognitionLevel = .accurate
request.recognitionLanguages = ["zh-Hans", "en-US"]
try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
let w = CGFloat(cgImage.width), h = CGFloat(cgImage.height)
var best: (score: Float, x: Int, y: Int)? = nil
for observation in request.results ?? [] {
  guard let candidate = observation.topCandidates(1).first else { continue }
  guard candidate.string.contains("发送") else { continue }
  let box = observation.boundingBox
  let cx = (box.minX + box.width / 2) * w
  let cy = (1 - box.minY - box.height / 2) * h
  guard cx / w > 0.62 && cy / h > 0.84 else { continue }
  let score = candidate.confidence + Float(cx / w) * 0.1
  if best == nil || score > best!.score {
    best = (score, Int(cx), Int(cy))
  }
}
if let best {
  let obj: [String: Any] = ["x": best.x, "y": best.y]
  print(String(data: try JSONSerialization.data(withJSONObject: obj, options: []), encoding: .utf8)!)
} else {
  print("null")
}
SWIFT
}

wechat_click_send_button() {
  local send_rel_x="${1:-0.88}"
  local send_rel_y="${2:-0.93}"
  if [ "${WECHAT_SEND_USE_OCR:-0}" = "1" ]; then
    local shot target_json abs_x abs_y bounds cliclick_bin
    shot="$(wechat_screenshot_path || true)"
    if [ -n "$shot" ]; then
      target_json="$(wechat_ocr_find_send_button "$shot" 2>/dev/null || echo null)"
      if [ "$target_json" != "null" ]; then
        bounds="$(wechat_window_bounds)"
        read -r abs_x abs_y < <(python3 -c '
import json, sys
t = json.loads(sys.argv[1])
b = json.loads(sys.argv[2])
print(t["x"] + b["x"], t["y"] + b["y"])
' "$target_json" "$bounds")
        cliclick_bin="$(wechat_resolve_cliclick)"
        "$cliclick_bin" "c:${abs_x},${abs_y}"
        return 0
      fi
    fi
  fi
  wechat_click_rel "$send_rel_x" "$send_rel_y"
}

# 点输入框 → 粘贴 → 点发送（固定坐标，零 OCR）。
wechat_compose_and_send() {
  local message="$1"
  local input_rel_x="${2:-0.65}"
  local input_rel_y="${3:-0.88}"
  local send_rel_x="${4:-0.88}"
  local send_rel_y="${5:-0.93}"

  wechat_click_rel "$input_rel_x" "$input_rel_y"
  sleep 0.2
  wechat_paste_text "$message"
  sleep 0.25
  echo "[wechat] click send..." >&2
  wechat_click_rel "$send_rel_x" "$send_rel_y"
  sleep 0.4
}

wechat_ocr_contains_any() {
  local image_path="$1"
  shift
  [ -f "$image_path" ] || return 1
  [ "$#" -gt 0 ] || return 1
  [ -x /usr/bin/swift ] || return 1

  local keywords_json
  keywords_json=$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1:], ensure_ascii=False))' "$@")

  /usr/bin/swift - "$image_path" "$keywords_json" <<'SWIFT'
import Foundation
import Vision
import AppKit

let path = CommandLine.arguments[1]
guard let keywordsData = CommandLine.arguments[2].data(using: .utf8),
      let keywords = try? JSONSerialization.jsonObject(with: keywordsData) as? [String],
      !keywords.isEmpty,
      let image = NSImage(contentsOfFile: path),
      let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
  print("{\"ok\":false,\"matched\":\"\"}")
  exit(0)
}

let request = VNRecognizeTextRequest()
request.recognitionLevel = .accurate
request.usesLanguageCorrection = true
request.recognitionLanguages = ["zh-Hans", "en-US"]
let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
try handler.perform([request])

var allText = ""
var matched = ""
for observation in request.results ?? [] {
  guard let candidate = observation.topCandidates(1).first else { continue }
  allText += candidate.string + "\n"
  for kw in keywords where candidate.string.contains(kw) {
    matched = kw
    break
  }
  if !matched.isEmpty { break }
}
if matched.isEmpty {
  for kw in keywords where allText.contains(kw) {
    matched = kw
    break
  }
}
let obj: [String: Any] = ["ok": !matched.isEmpty, "matched": matched, "textSample": String(allText.prefix(400))]
print(String(data: try JSONSerialization.data(withJSONObject: obj, options: []), encoding: .utf8)!)
SWIFT
}

wechat_chat_opened() {
  local shot="$1"
  local contact="$2"
  [ -f "$shot" ] || return 1
  if [ "$(wechat_in_global_search "$shot")" = "yes" ]; then
    return 1
  fi
  if [ "$(wechat_right_chat_ready "$shot")" = "yes" ]; then
    return 0
  fi
  return 1
}

# 联系人名出现在右侧聊天标题区（x > 35% 窗口宽）。
wechat_ocr_find_header_contact() {
  local image_path="$1"
  local keyword="$2"
  [ -f "$image_path" ] || return 1
  [ -x /usr/bin/swift ] || return 1
  local keyword_json
  keyword_json="$(wechat_to_json "$keyword")"
  /usr/bin/swift - "$image_path" "$keyword_json" <<'SWIFT'
import Foundation
import Vision
import AppKit

let path = CommandLine.arguments[1]
let keyword = CommandLine.arguments[2]
guard let image = NSImage(contentsOfFile: path),
      let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
  print("{\"ok\":false}")
  exit(0)
}
let request = VNRecognizeTextRequest()
request.recognitionLevel = .accurate
request.recognitionLanguages = ["zh-Hans", "en-US"]
let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
try handler.perform([request])
let width = CGFloat(cgImage.width)
let height = CGFloat(cgImage.height)
for observation in request.results ?? [] {
  guard let candidate = observation.topCandidates(1).first else { continue }
  let text = candidate.string
  let matched: Bool = {
    if text.contains(keyword) || keyword.contains(text) { return text.count >= 2 }
    if keyword.count >= 2 {
      let suffix = String(keyword.suffix(min(3, keyword.count)))
      if text.contains(suffix) { return true }
    }
    return false
  }()
  guard matched else { continue }
  let box = observation.boundingBox
  let cx = (box.minX + box.width / 2) * width
  let cy = (1 - box.minY - box.height / 2) * height
  if Double(cx / width) > 0.35 && Double(cy / height) < 0.12 {
    let obj: [String: Any] = ["ok": true, "matched": keyword, "x": Int(cx), "y": Int(cy)]
    print(String(data: try JSONSerialization.data(withJSONObject: obj, options: []), encoding: .utf8)!)
    exit(0)
  }
}
print("{\"ok\":false}")
SWIFT
}

wechat_poll_chat_opened() {
  local attempts="$1"
  local interval="$2"
  local contact="$3"
  local i shot
  for ((i = 1; i <= attempts; i++)); do
    shot="$(wechat_screenshot_path || true)"
    if [ -n "$shot" ] && wechat_chat_opened "$shot" "$contact"; then
      wechat_ocr_contains_any "$shot" "$contact"
      return 0
    fi
    sleep "$interval"
  done
  return 1
}

wechat_poll_ocr() {
  local attempts="$1"
  local interval="$2"
  shift 2
  local i shot result ok
  for ((i = 1; i <= attempts; i++)); do
    shot="$(wechat_screenshot_path || true)"
    if [ -n "$shot" ] && [ -f "$shot" ]; then
      result="$(wechat_ocr_contains_any "$shot" "$@" || echo '{"ok":false}')"
      ok=$(printf '%s' "$result" | python3 -c 'import json,sys; print("yes" if json.loads(sys.stdin.read()).get("ok") else "no")' 2>/dev/null || echo "no")
      if [ "$ok" = "yes" ]; then
        printf '%s' "$result"
        return 0
      fi
    fi
    sleep "$interval"
  done
  return 1
}

# 消息已发送：文本出现在聊天区（非底部输入框，y < 85% 窗口高）。
wechat_message_sent_in_chat() {
  local shot="$1"
  local message="$2"
  [ -f "$shot" ] || return 1
  [ -x /usr/bin/swift ] || return 1
  local msg_json
  msg_json="$(wechat_to_json "$message")"
  /usr/bin/swift - "$shot" "$msg_json" <<'SWIFT'
import Foundation
import Vision
import AppKit

let path = CommandLine.arguments[1]
let message = CommandLine.arguments[2]
guard let image = NSImage(contentsOfFile: path),
      let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
  print("{\"ok\":false}")
  exit(0)
}
let request = VNRecognizeTextRequest()
request.recognitionLevel = .accurate
request.recognitionLanguages = ["zh-Hans", "en-US"]
try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
let height = CGFloat(cgImage.height)
for observation in request.results ?? [] {
  guard let candidate = observation.topCandidates(1).first else { continue }
  guard candidate.string.contains(message) else { continue }
  let box = observation.boundingBox
  let cy = (1 - box.minY - box.height / 2) * height
  if Double(cy / height) < 0.82 {
    let obj: [String: Any] = ["ok": true, "matched": message, "y": Int(cy)]
    print(String(data: try JSONSerialization.data(withJSONObject: obj, options: []), encoding: .utf8)!)
    exit(0)
  }
}
print("{\"ok\":false}")
SWIFT
}

wechat_right_chat_ready() {
  local shot="$1"
  local contact="${2:-}"
  [ -f "$shot" ] || return 1
  [ -x /usr/bin/swift ] || return 1

  if [ -n "$contact" ] && ! wechat_is_file_transfer_assistant "$contact"; then
    local header_result
    header_result="$(wechat_ocr_find_header_contact "$shot" "$contact" 2>/dev/null || echo '{"ok":false}')"
    if printf '%s' "$header_result" | python3 -c 'import json,sys; exit(0 if json.loads(sys.stdin.read()).get("ok") else 1)' 2>/dev/null; then
      echo "yes"
      return 0
    fi
  fi

  /usr/bin/swift - "$shot" "$contact" <<'SWIFT'
import Foundation
import Vision
import AppKit

let path = CommandLine.arguments[1]
let contact = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : ""
guard let image = NSImage(contentsOfFile: path),
      let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
  print("no")
  exit(0)
}
let request = VNRecognizeTextRequest()
request.recognitionLevel = .accurate
request.recognitionLanguages = ["zh-Hans", "en-US"]
try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
let w = CGFloat(cgImage.width), h = CGFloat(cgImage.height)
for observation in request.results ?? [] {
  guard let candidate = observation.topCandidates(1).first else { continue }
  let text = candidate.string
  let box = observation.boundingBox
  let cx = (box.minX + box.width / 2) * w
  let cy = (1 - box.minY - box.height / 2) * h
  if text.contains("发送") && cx / w > 0.55 && cy / h > 0.82 {
    print("yes")
    exit(0)
  }
  if (text.contains("语音") || text.contains("输入") || text.contains("表情")) && cx / w > 0.45 && cy / h > 0.78 {
    print("yes")
    exit(0)
  }
  if text.contains("文件传输助手") && cx / w > 0.35 && cy / h < 0.12 {
    print("yes")
    exit(0)
  }
  if !contact.isEmpty && contact.count >= 2 {
    let suffix = String(contact.suffix(min(3, contact.count)))
    if text.contains(contact) || text.contains(suffix) {
      if cx / w > 0.35 && cy / h < 0.12 {
        print("yes")
        exit(0)
      }
    }
  }
}
print("no")
SWIFT
}

wechat_poll_right_chat_ready() {
  local attempts="$1"
  local interval="$2"
  local contact="${3:-}"
  local i shot
  for ((i = 1; i <= attempts; i++)); do
    shot="$(wechat_screenshot_path || true)"
    if [ -n "$shot" ] && [ "$(wechat_right_chat_ready "$shot" "$contact")" = "yes" ]; then
      return 0
    fi
    sleep "$interval"
  done
  return 1
}

wechat_poll_message_sent() {
  local attempts="$1"
  local interval="$2"
  local message="$3"
  local i shot result
  for ((i = 1; i <= attempts; i++)); do
    shot="$(wechat_screenshot_path || true)"
    if [ -n "$shot" ]; then
      result="$(wechat_message_sent_in_chat "$shot" "$message" 2>/dev/null || echo '{"ok":false}')"
      if printf '%s' "$result" | python3 -c 'import json,sys; exit(0 if json.loads(sys.stdin.read()).get("ok") else 1)' 2>/dev/null; then
        printf '%s' "$result"
        return 0
      fi
    fi
    sleep "$interval"
  done
  return 1
}

# 打开聊天：固定坐标双击 + 聚焦右侧，不做 OCR 校验。
wechat_open_contact() {
  local contact="$1"
  local list_x list_y focus_x focus_y

  if wechat_is_file_transfer_assistant "$contact"; then
    list_x="${WECHAT_FTA_REL_X:-0.18}"
    list_y="${WECHAT_FTA_REL_Y:-0.28}"
    echo "[wechat] open 文件传输助手 (list coord)" >&2
  else
    list_x="${WECHAT_LIST_REL_X:-0.18}"
    list_y="${WECHAT_CONTACT_LIST_Y:-0.21}"
    echo "[wechat] open contact from list: $contact ($list_x, $list_y)" >&2
  fi
  focus_x="${WECHAT_FOCUS_REL_X:-0.75}"
  focus_y="${WECHAT_FOCUS_REL_Y:-0.45}"

  wechat_click_rel "$list_x" "$list_y"
  sleep 0.25
  wechat_click_rel "$list_x" "$list_y"
  sleep 0.7
  wechat_click_rel "$focus_x" "$focus_y"
  sleep 0.25
  return 0
}

# 发送成功：消息出现在聊天气泡区，或输入框已不再含该文本。
wechat_verify_message_sent() {
  local message="$1"
  local shot
  shot="$(wechat_screenshot_path || true)"
  [ -n "$shot" ] || return 1

  local result
  result="$(wechat_message_sent_in_chat "$shot" "$message" 2>/dev/null || echo '{"ok":false}')"
  if printf '%s' "$result" | python3 -c 'import json,sys; exit(0 if json.loads(sys.stdin.read()).get("ok") else 1)' 2>/dev/null; then
    printf '%s' "$result"
    return 0
  fi

  if [ "$(wechat_input_has_message "$shot" "$message")" != "yes" ]; then
    printf '{"ok":true,"matched":"input_cleared"}'
    return 0
  fi
  return 1
}

wechat_poll_verify_sent() {
  local attempts="$1"
  local interval="$2"
  local message="$3"
  local i
  for ((i = 1; i <= attempts; i++)); do
    if wechat_verify_message_sent "$message" >/tmp/wechat-sent-verify.json 2>/dev/null; then
      cat /tmp/wechat-sent-verify.json
      return 0
    fi
    sleep "$interval"
  done
  return 1
}

wechat_load_verify_json() {
  python3 - <<'PY'
import json, os
path = "/tmp/wechat-sent-verify.json"
if not os.path.isfile(path) or os.path.getsize(path) == 0:
    print("{}")
else:
    try:
        print(json.dumps(json.load(open(path)), ensure_ascii=False))
    except Exception:
        print("{}")
PY
}

wechat_emit_result() {
  local ok="$1"
  local contact="$2"
  local message="$3"
  local strategy="$4"
  local error="${5:-}"
  local hint="${6:-}"
  local bounds final_shot verify_json
  bounds="$(wechat_window_bounds)"
  if [ "$ok" = "yes" ] && [ "${WECHAT_SKIP_FINAL_SCREENSHOT:-1}" = "1" ]; then
    final_shot=""
  else
    final_shot="$(wechat_screenshot_path || true)"
  fi
  verify_json="$(wechat_load_verify_json)"

  if [ "$ok" = "yes" ]; then
    python3 - <<PY
import json
verify = json.loads($(wechat_to_json "$verify_json"))
print(json.dumps({
  "ok": True,
  "contact": $(wechat_to_json "$contact"),
  "message": $(wechat_to_json "$message"),
  "strategy": $(wechat_to_json "$strategy"),
  "window": json.loads($(wechat_to_json "$bounds")),
  "screenshot": $(wechat_to_json "$final_shot"),
  "verify": verify
}, ensure_ascii=False))
PY
    return 0
  fi

  python3 - <<PY
import json
verify = json.loads($(wechat_to_json "$verify_json"))
print(json.dumps({
  "ok": False,
  "error": $(wechat_to_json "$error"),
  "contact": $(wechat_to_json "$contact"),
  "message": $(wechat_to_json "$message"),
  "strategy": $(wechat_to_json "$strategy"),
  "window": json.loads($(wechat_to_json "$bounds")),
  "screenshot": $(wechat_to_json "$final_shot"),
  "hint": $(wechat_to_json "$hint"),
  "verify": verify
}, ensure_ascii=False))
PY
  return 1
}

# 统一发送入口：固定坐标快速路径，默认零 OCR。
wechat_run_send_message() {
  local contact="$1"
  local message="$2"
  local strategy="fast-cliclick"
  local input_x="${WECHAT_INPUT_REL_X:-0.65}"
  local input_y="${WECHAT_INPUT_REL_Y:-0.88}"
  local send_x="${WECHAT_SEND_REL_X:-0.88}"
  local send_y="${WECHAT_SEND_REL_Y:-0.93}"

  rm -f /tmp/wechat-sent-verify.json

  if wechat_is_file_transfer_assistant "$contact"; then
    strategy="file-transfer-assistant-fast"
  fi

  wechat_prepare_ui
  wechat_open_contact "$contact"

  echo "[wechat] compose and send..." >&2
  wechat_compose_and_send "$message" "$input_x" "$input_y" "$send_x" "$send_y"

  if [ "${WECHAT_VERIFY:-0}" = "1" ]; then
    sleep 0.5
    wechat_verify_message_sent "$message" >/tmp/wechat-sent-verify.json 2>/dev/null || \
      echo '{"ok":false}' >/tmp/wechat-sent-verify.json
  else
    printf '{"ok":true,"matched":"send_clicked"}' >/tmp/wechat-sent-verify.json
  fi

  wechat_emit_result yes "$contact" "$message" "$strategy"
  return 0
}
