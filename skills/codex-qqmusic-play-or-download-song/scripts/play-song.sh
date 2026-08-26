#!/usr/bin/env bash
# QQ 音乐搜索并播放指定歌曲（固化流程，全程无 LLM 决策）
# 用法：play-song.sh "歌名" "歌手"
# 例：play-song.sh "晴天" "周杰伦"

set -euo pipefail

SONG="${1:-}"
ARTIST="${2:-}"

if [ -z "$SONG" ]; then
  echo "Usage: $0 <song> [artist]" >&2
  exit 2
fi

QUERY="$SONG"
[ -n "$ARTIST" ] && QUERY="$SONG $ARTIST"

# 定位 cua-router-basic
SKILL_ROOT="${CUA_ROUTER_INSTALL_DIR:-${HOME}/.automan/claude-code-agents/cua-agent/skills/cua-router-basic}"
if [ ! -f "$SKILL_ROOT/SKILL.md" ]; then
  SKILL_ROOT="${HOME}/.cursor/skills/cua-router-basic"
fi
if [ ! -f "$SKILL_ROOT/SKILL.md" ]; then
  echo "cua-router-basic not installed. Run its update-remote.sh first." >&2
  exit 1
fi

QQM_BUNDLE="com.tencent.QQMusicMac"

to_json() {
  python3 -c 'import json,sys; print(json.dumps(sys.argv[1], ensure_ascii=False))' "$1"
}

json_field() {
  python3 -c 'import json,sys; data=json.loads(sys.stdin.read()); v=data.get(sys.argv[1], ""); print(v if v is not None else "")' "$1"
}

file_url_to_path() {
  python3 -c 'import sys,urllib.parse; u=sys.argv[1]; print(urllib.parse.unquote(u[7:] if u.startswith("file://") else u))' "$1"
}

ax_play_button_center() {
  if [ ! -x /usr/bin/swift ]; then
    echo "null"
    return 0
  fi

  /usr/bin/swift - <<'SWIFT' 2>/dev/null || echo "null"
import Foundation
import AppKit
import ApplicationServices

let bundle = "com.tencent.QQMusicMac"
guard let runningApp = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundle }) else {
  print("null")
  exit(0)
}
let app = AXUIElementCreateApplication(runningApp.processIdentifier)

func attr(_ el: AXUIElement, _ name: CFString) -> AnyObject? {
  var value: AnyObject?
  return AXUIElementCopyAttributeValue(el, name, &value) == .success ? value : nil
}

func str(_ el: AXUIElement, _ name: CFString) -> String {
  (attr(el, name) as? String) ?? ""
}

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

func children(_ el: AXUIElement) -> [AXUIElement] {
  (attr(el, kAXChildrenAttribute as CFString) as? [AXUIElement]) ?? []
}

func findPlaybackPanel(_ el: AXUIElement) -> AXUIElement? {
  let title = str(el, kAXTitleAttribute as CFString)
  let desc = str(el, kAXDescriptionAttribute as CFString)
  if title.contains("播放控制栏") || desc.contains("播放控制栏") { return el }
  for child in children(el) {
    if let found = findPlaybackPanel(child) { return found }
  }
  return nil
}

func findPlayButton(_ el: AXUIElement) -> AXUIElement? {
  let title = str(el, kAXTitleAttribute as CFString)
  let desc = str(el, kAXDescriptionAttribute as CFString)
  if title == "播放" || title == "继续播放" || desc == "播放" { return el }
  for child in children(el) {
    if let found = findPlayButton(child) { return found }
  }
  return nil
}

let roots = children(app)
guard let panel = roots.compactMap({ findPlaybackPanel($0) }).first,
      let button = findPlayButton(panel),
      let window = roots.first(where: { str($0, kAXRoleAttribute as CFString) == (kAXWindowRole as String) }),
      let wp = point(window, kAXPositionAttribute as CFString),
      let bp = point(button, kAXPositionAttribute as CFString),
      let bs = size(button, kAXSizeAttribute as CFString) else {
  print("null")
  exit(0)
}
let obj: [String: Any] = ["text": "ax-playback-center", "x": Int(bp.x - wp.x + bs.width / 2), "y": Int(bp.y - wp.y + bs.height / 2), "w": Int(bs.width), "h": Int(bs.height)]
print(String(data: try JSONSerialization.data(withJSONObject: obj, options: []), encoding: .utf8)!)
SWIFT
}

ocr_play_button_target() {
  local image_path="$1"

  if [ -z "$image_path" ] || [ ! -f "$image_path" ] || [ ! -x /usr/bin/swift ]; then
    echo "null"
    return 0
  fi

  /usr/bin/swift - "$image_path" <<'SWIFT' 2>/dev/null || echo "null"
import Foundation
import Vision
import AppKit

let path = CommandLine.arguments[1]
guard let image = NSImage(contentsOfFile: path), let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
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
var rows: [[String: Any]] = []

for obs in request.results ?? [] {
  guard let text = obs.topCandidates(1).first?.string else { continue }
  let normalized = text.replacingOccurrences(of: " ", with: "")
  guard normalized.contains("播放") else { continue }
  let b = obs.boundingBox
  let x = Int((b.origin.x + b.size.width / 2) * width)
  let y = Int((1 - b.origin.y - b.size.height / 2) * height)
  let w = Int(b.size.width * width)
  let h = Int(b.size.height * height)
  rows.append(["text": text, "x": x, "y": y, "w": w, "h": h])
}

let bottomRows = rows.filter { ($0["y"] as! Int) > Int(height * 0.65) }
if let first = bottomRows.sorted(by: { ($0["y"] as! Int) > ($1["y"] as! Int) }).first {
  print(String(data: try JSONSerialization.data(withJSONObject: first, options: []), encoding: .utf8)!)
} else {
  print("null")
}
SWIFT
}

vision_play_button_target() {
  local image_path="$1"

  if [ -z "$image_path" ] || [ ! -f "$image_path" ] || [ ! -x /usr/bin/swift ]; then
    echo "null"
    return 0
  fi

  /usr/bin/swift - "$image_path" <<'SWIFT' 2>/dev/null || echo "null"
import Foundation
import AppKit

let path = CommandLine.arguments[1]
guard let image = NSImage(contentsOfFile: path), let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil), let data = cg.dataProvider?.data, let ptr = CFDataGetBytePtr(data) else {
  print("null")
  exit(0)
}

let width = cg.width
let height = cg.height
let bytesPerPixel = max(1, cg.bitsPerPixel / 8)
let bytesPerRow = cg.bytesPerRow
let length = CFDataGetLength(data)
var xs: [Int] = []
var ys: [Int] = []

for y in Int(Double(height) * 0.65)..<height {
  for x in 0..<width {
    let i = y * bytesPerRow + x * bytesPerPixel
    if i + 2 >= length { continue }
    let r = Int(ptr[i])
    let g = Int(ptr[i + 1])
    let b = Int(ptr[i + 2])
    if g > 145 && r < 140 && b < 160 && g > r + 35 && g > b + 25 {
      xs.append(x)
      ys.append(y)
    }
  }
}

if xs.isEmpty {
  print("null")
} else {
  let minX = xs.min()!, maxX = xs.max()!, minY = ys.min()!, maxY = ys.max()!
  let obj: [String: Any] = ["text": "green-play-icon", "x": (minX + maxX) / 2, "y": (minY + maxY) / 2, "w": maxX - minX + 1, "h": maxY - minY + 1]
  print(String(data: try JSONSerialization.data(withJSONObject: obj, options: []), encoding: .utf8)!)
}
SWIFT
}

ocr_song_target() {
  local image_path="$1"
  local song="$2"
  local artist="$3"

  if [ -z "$image_path" ] || [ ! -f "$image_path" ] || [ ! -x /usr/bin/swift ]; then
    echo "null"
    return 0
  fi

  /usr/bin/swift - "$image_path" "$song" "$artist" <<'SWIFT' 2>/dev/null || echo "null"
import Foundation
import Vision
import AppKit

let path = CommandLine.arguments[1]
let song = CommandLine.arguments[2]
let artist = CommandLine.arguments.count > 3 ? CommandLine.arguments[3] : ""
let normalizedSong = song.replacingOccurrences(of: " ", with: "")
let normalizedArtist = artist.replacingOccurrences(of: " ", with: "")

guard let image = NSImage(contentsOfFile: path), let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
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
var rows: [[String: Any]] = []

for obs in request.results ?? [] {
  guard let text = obs.topCandidates(1).first?.string else { continue }
  let b = obs.boundingBox
  let x = Int((b.origin.x + b.size.width / 2) * width)
  let y = Int((1 - b.origin.y - b.size.height / 2) * height)
  let w = Int(b.size.width * width)
  let h = Int(b.size.height * height)
  let normalized = text.replacingOccurrences(of: " ", with: "")
  let songHit = normalized.contains(normalizedSong)
  let exactSongHit = normalized == normalizedSong || normalized == "《" + normalizedSong + "》"
  let artistHit = !normalizedArtist.isEmpty && normalized.contains(normalizedArtist)
  if y > 250 && (songHit || artistHit) {
    rows.append(["text": text, "x": x, "y": y, "w": w, "h": h, "songHit": songHit, "exactSongHit": exactSongHit, "artistHit": artistHit])
  }
}

let exactSongRows = rows.filter { ($0["exactSongHit"] as? Bool) == true }.sorted { ($0["y"] as! Int) < ($1["y"] as! Int) }
if let first = exactSongRows.first {
  print(String(data: try JSONSerialization.data(withJSONObject: first, options: []), encoding: .utf8)!)
  exit(0)
}

let artistRows = rows.filter { ($0["artistHit"] as? Bool) == true }.sorted { ($0["y"] as! Int) < ($1["y"] as! Int) }
if let first = artistRows.first {
  var inferred = first
  inferred["text"] = "inferred-title-from-artist:" + (first["text"] as! String)
  inferred["x"] = 300
  inferred["y"] = max(260, (first["y"] as! Int) - 20)
  print(String(data: try JSONSerialization.data(withJSONObject: inferred, options: []), encoding: .utf8)!)
  exit(0)
}

let songRows = rows.filter { ($0["songHit"] as? Bool) == true }.sorted { ($0["y"] as! Int) < ($1["y"] as! Int) }
if let first = songRows.first {
  print(String(data: try JSONSerialization.data(withJSONObject: first, options: []), encoding: .utf8)!)
  exit(0)
}

print("null")
SWIFT
}

echo "[qqmusic] ensure cua-router..."
bash "$SKILL_ROOT/scripts/ensure-ready.sh" >/dev/null

echo "[qqmusic] launch app..."
open -b "$QQM_BUNDLE" || {
  echo "QQ Music not installed (bundle=$QQM_BUNDLE)" >&2; exit 1;
}

# 等窗口就绪：最多 8 秒
for i in 1 2 3 4 5 6 7 8; do
  if osascript -e "tell application \"System Events\" to exists (window 1 of process \"QQ音乐\")" 2>/dev/null | grep -q true; then
    break
  fi
  sleep 1
done

echo "[qqmusic] activate app..."
osascript -e "tell application id \"$QQM_BUNDLE\" to activate" >/dev/null
sleep 1

# 写剪贴板，后续用 sky.press_key(Command+v) 粘贴到 QQ 音乐搜索框
echo "[qqmusic] set clipboard: $QUERY"
printf '%s' "$QUERY" | pbcopy

echo "[qqmusic] type into search..."
SONG_JSON=$(to_json "$SONG")
ARTIST_JSON=$(to_json "$ARTIST")
SEARCH_JS=$(cat <<'JS'
{
  const APP = "com.tencent.QQMusicMac";
  const SONG = __SONG_JSON__;
  const wait = ms => new Promise(r => setTimeout(r, ms));

  const isSearchResultPage = text => {
    if (text.includes(SONG)) return true;
    const hasResultTabs = ["歌曲", "视频", "专辑"].every(label => text.includes(label));
    const hasResultActions = ["播放", "下载", "批量"].every(label => text.includes(label));
    return hasResultTabs && hasResultActions;
  };

  await sky.get_app_state({ app: APP, disableDiff: true });
  await sky.click({ app: APP, x: 438, y: 40 });
  await wait(700);
  await sky.get_app_state({ app: APP, disableDiff: true });
  await sky.press_key({ app: APP, key: "Command+a" });
  await wait(120);
  await sky.press_key({ app: APP, key: "Delete" });
  await wait(120);
  await sky.press_key({ app: APP, key: "Command+v" });
  await wait(1200);
  await sky.get_app_state({ app: APP, disableDiff: true });
  await sky.press_key({ app: APP, key: "Down" });
  await wait(400);
  await sky.get_app_state({ app: APP, disableDiff: true });
  await sky.press_key({ app: APP, key: "Return" });
  await wait(4000);
  let state = await sky.get_app_state({ app: APP, disableDiff: true });
  if (!state.text.includes(SONG)) {
    await sky.click({ app: APP, x: 438, y: 40 });
    await wait(500);
    await sky.get_app_state({ app: APP, disableDiff: true });
    await sky.press_key({ app: APP, key: "Return" });
    await wait(4500);
    state = await sky.get_app_state({ app: APP, disableDiff: true });
  }

  nodeRepl.write(JSON.stringify({
    searchHasSong: state.text.includes(SONG),
    isResultPage: isSearchResultPage(state.text),
    screenshot: state.screenshot && state.screenshot.url
  }));
}
JS
)
SEARCH_JS=${SEARCH_JS/__SONG_JSON__/$SONG_JSON}
SEARCH_OUT=$(bash "$SKILL_ROOT/scripts/exec.sh" -t 60000 "$SEARCH_JS")
SEARCH_JSON=$(printf '%s' "$SEARCH_OUT" | python3 -c 'import sys,json,re; s=sys.stdin.read(); m=re.findall(r"\{.*\}", s, re.S); print(m[-1] if m else "{}")')
SCREENSHOT_URL=$(printf '%s' "$SEARCH_JSON" | json_field screenshot)
SCREENSHOT_PATH=$(file_url_to_path "$SCREENSHOT_URL")
OCR_TARGET_JSON=$(ocr_song_target "$SCREENSHOT_PATH" "$SONG" "$ARTIST")
AX_PLAY_TARGET_JSON=$(ax_play_button_center)
OCR_PLAY_TARGET_JSON=$(ocr_play_button_target "$SCREENSHOT_PATH")
if [ -z "$OCR_PLAY_TARGET_JSON" ] || [ "$OCR_PLAY_TARGET_JSON" = "null" ]; then
  OCR_PLAY_TARGET_JSON=$(vision_play_button_target "$SCREENSHOT_PATH")
fi

if [ -z "$OCR_TARGET_JSON" ]; then
  OCR_TARGET_JSON="null"
fi
if [ -z "$AX_PLAY_TARGET_JSON" ]; then
  AX_PLAY_TARGET_JSON="null"
fi
if [ -z "$OCR_PLAY_TARGET_JSON" ]; then
  OCR_PLAY_TARGET_JSON="null"
fi

if [ "$OCR_TARGET_JSON" != "null" ]; then
  echo "[qqmusic] OCR target: $OCR_TARGET_JSON"
else
  echo "[qqmusic] OCR target: null"
fi
if [ "$AX_PLAY_TARGET_JSON" != "null" ]; then
  echo "[qqmusic] AX play target: $AX_PLAY_TARGET_JSON"
else
  echo "[qqmusic] AX play target: null"
fi
if [ "$OCR_PLAY_TARGET_JSON" != "null" ]; then
  echo "[qqmusic] OCR play target: $OCR_PLAY_TARGET_JSON"
else
  echo "[qqmusic] OCR play target: null"
fi

echo "[qqmusic] play by AX/OCR/coord-scan..."
PLAY_JS=$(cat <<'JS'
{
  const APP = "com.tencent.QQMusicMac";
  const SONG = __SONG_JSON__;
  const ARTIST = __ARTIST_JSON__;
  const OCR_TARGET = __OCR_TARGET_JSON__;
  const AX_PLAY_TARGET = __AX_PLAY_TARGET_JSON__;
  const OCR_PLAY_TARGET = __OCR_PLAY_TARGET_JSON__;
  const wait = ms => new Promise(r => setTimeout(r, ms));

  const readNowPlaying = text => {
    const line = text.split("\n").find(l => /歌曲名：/.test(l) && /歌手名：/.test(l)) || "";
    const m = line.match(/歌曲名：(.+?) - 歌手名：(.+?)(?:\s|$)/);
    return { line: line.trim(), title: m ? m[1].trim() : "", artist: m ? m[2].trim() : "" };
  };

  const matchesTarget = np => {
    if (!np.title || !np.title.includes(SONG)) return false;
    if (ARTIST && np.artist && !np.artist.includes(ARTIST)) return false;
    return true;
  };

  const parseAxLines = text => text.split("\n").map((line, order) => {
    const m = line.match(/^\s*(\d+) (文本|text|按钮|button|链接|link) (.+?)\s*$/);
    return m ? { order, idx: Number(m[1]), role: m[2], title: m[3].trim(), line } : null;
  }).filter(Boolean);

  const isSearchResultPage = text => {
    if (text.includes(SONG)) return true;
    const hasResultTabs = ["歌曲", "视频", "专辑"].every(label => text.includes(label));
    const hasResultActions = ["播放", "下载", "批量"].every(label => text.includes(label));
    return hasResultTabs && hasResultActions;
  };

  const getPlaybackControl = text => {
    const axLines = parseAxLines(text);
    const candidates = axLines.filter(l => /^(播放|继续播放|开始播放|播放\/暂停|暂停|暂停播放)$/.test(l.title));
    if (!candidates.length) return null;
    return candidates[candidates.length - 1];
  };

  const isPlayingState = text => /按钮\s+暂停|按钮\s+暂停播放|暂停播放/.test(text);

  const clickAndRead = async ({ x, y, label, strategy }) => {
    await sky.click({ app: APP, x, y });
    await wait(900);
    const stateAfterPlay = await sky.get_app_state({ app: APP, disableDiff: true });
    return { np: readNowPlaying(stateAfterPlay.text), screenshot: stateAfterPlay.screenshot && stateAfterPlay.screenshot.url, attempt: label, x, y, strategy };
  };

  const tryMenuPlay = async () => {
    try {
      await sky.get_app_state({ app: APP, disableDiff: true });
      const { spawnSync } = await import("node:child_process");
      const res = spawnSync("/usr/bin/osascript", [
        "-e", "tell application id \"com.tencent.QQMusicMac\" to activate",
        "-e", "tell application \"System Events\" to tell process \"QQ音乐\" to click menu item \"播放\" of menu \"播放控制\" of menu bar 1"
      ], { encoding: "utf8" });
      await wait(900);
      return res.status === 0;
    } catch {
      return false;
    }
  };

  const tryClickPlaybackPlay = async () => {
    const freshState = await sky.get_app_state({ app: APP, disableDiff: true });
    const playButton = getPlaybackControl(freshState.text);
    if (playButton && /暂停/.test(playButton.title)) {
      return { np: readNowPlaying(freshState.text), screenshot: freshState.screenshot && freshState.screenshot.url, attempt: `already-playing-button:${playButton.title}`, x: undefined, y: undefined, strategy: "already-playing-button" };
    }

    if (AX_PLAY_TARGET && Number.isFinite(AX_PLAY_TARGET.x) && Number.isFinite(AX_PLAY_TARGET.y)) {
      const r = await clickAndRead({ x: AX_PLAY_TARGET.x, y: AX_PLAY_TARGET.y, label: `ax-center-play:${AX_PLAY_TARGET.text}@${AX_PLAY_TARGET.x},${AX_PLAY_TARGET.y}`, strategy: "ax-center-play" });
      const state = await sky.get_app_state({ app: APP, disableDiff: true });
      if (isPlayingState(state.text)) return r;
    }

    if (OCR_PLAY_TARGET && Number.isFinite(OCR_PLAY_TARGET.x) && Number.isFinite(OCR_PLAY_TARGET.y)) {
      const r = await clickAndRead({ x: OCR_PLAY_TARGET.x, y: OCR_PLAY_TARGET.y, label: `ocr-play:${OCR_PLAY_TARGET.text}@${OCR_PLAY_TARGET.x},${OCR_PLAY_TARGET.y}`, strategy: "ocr-play" });
      const state = await sky.get_app_state({ app: APP, disableDiff: true });
      if (isPlayingState(state.text)) return r;
    }

    if (await tryMenuPlay()) {
      await wait(900);
      const state = await sky.get_app_state({ app: APP, disableDiff: true });
      if (isPlayingState(state.text)) {
        const np = readNowPlaying(state.text);
        return {
          np,
          screenshot: state.screenshot && state.screenshot.url,
          attempt: "menu-play:Command+Shift+M",
          x: undefined,
          y: undefined,
          strategy: "menu-play"
        };
      }
    }

    return null;
  };


  const ensureTargetPlaying = async current => {
    let state = await sky.get_app_state({ app: APP, disableDiff: true });
    let np = readNowPlaying(state.text);
    if (matchesTarget(np) && isPlayingState(state.text)) {
      return { ...current, np, screenshot: state.screenshot && state.screenshot.url, playing: true };
    }

    const clicked = await tryClickPlaybackPlay();
    state = await sky.get_app_state({ app: APP, disableDiff: true });
    np = readNowPlaying(state.text);
    return {
      np,
      screenshot: state.screenshot && state.screenshot.url,
      attempt: `${current.attempt || "matched-row"} + ${clicked ? clicked.attempt : "play-button-missing"}`,
      x: current.x,
      y: current.y,
      strategy: `${current.strategy || "matched-row"}+ensure-playing`,
      playing: matchesTarget(np) && isPlayingState(state.text)
    };
  };

  const findResultClickTarget = text => {
    const axLines = parseAxLines(text);
    const headerOrder = axLines.find(l => /歌名\s*\/\s*歌手/.test(l.title))?.order ?? -1;
    const tabOrder = axLines.find(l => l.title === "歌曲")?.order ?? -1;
    const startOrder = headerOrder >= 0 ? headerOrder : tabOrder;
    if (startOrder < 0) return null;
    const resultLines = axLines.filter(l => l.order > startOrder);
    let firstSong = null;
    let best = null;

    for (let i = 0; i < resultLines.length; i++) {
      const item = resultLines[i];
      const title = item.title;
      if (/歌曲名：|歌手名：|专辑|时长|播放|下载|批量|更多|MV|VIP|SQ|HQ|臻品|全景声|歌名\s*\/\s*歌手/.test(title)) continue;
      if (/^(歌曲|视频|专辑|歌单|歌词|歌手|用户|有声|播放|下载|批量)$/.test(title)) continue;
      if (/^\d{1,2}:\d{2}$/.test(title)) continue;

      const near = resultLines.slice(Math.max(0, i - 4), i + 8).map(l => l.title).join("\n");
      const looksLikeSong = title.includes(SONG) || (ARTIST && near.includes(ARTIST)) || /\d{1,2}:\d{2}/.test(near);
      if (!looksLikeSong) continue;

      if (!firstSong) firstSong = { idx: item.idx, title, score: 0 };
      if (!title.includes(SONG)) continue;

      let score = 1;
      if (ARTIST && title.includes(ARTIST)) score = 4;
      else if (ARTIST && near.includes(ARTIST)) score = 3;
      else if (!ARTIST) score = 2;
      if (!best || score > best.score) best = { idx: item.idx, title, score };
    }

    return best || firstSong;
  };

  const tryPlayAt = async ({ element_index, x, y, label, strategy, click_count = 1 }) => {
    await sky.get_app_state({ app: APP, disableDiff: true });
    if (element_index != null) {
      await sky.click({ app: APP, element_index, click_count });
    } else {
      await sky.click({ app: APP, x, y, click_count });
    }
    await wait(2200);
    const state = await sky.get_app_state({ app: APP, disableDiff: true });
    const np = readNowPlaying(state.text);
    return await ensureTargetPlaying({ np, screenshot: state.screenshot && state.screenshot.url, attempt: label, x, y, strategy });
  };

  let state = await sky.get_app_state({ app: APP, disableDiff: true });
  const searchHasSong = state.text.includes(SONG);
  const isResultPage = isSearchResultPage(state.text);
  const resultTarget = findResultClickTarget(state.text);
  const coordCandidates = [
    { x: 285, y: 315 },
    { x: 320, y: 315 },
    { x: 285, y: 355 },
    { x: 320, y: 355 },
    { x: 285, y: 395 },
    { x: 320, y: 395 }
  ];

  const attempts = [];
  if (resultTarget) attempts.push({ element_index: resultTarget.idx, label: `ax:${resultTarget.title}`, strategy: "ax" });
  if (OCR_TARGET && Number.isFinite(OCR_TARGET.x) && Number.isFinite(OCR_TARGET.y)) {
    attempts.push({ x: OCR_TARGET.x, y: OCR_TARGET.y, label: `ocr:${OCR_TARGET.text}@${OCR_TARGET.x},${OCR_TARGET.y}`, strategy: "ocr" });
    attempts.push({ x: 285, y: OCR_TARGET.y, label: `row-play:${OCR_TARGET.text}@285,${OCR_TARGET.y}`, strategy: "row-play", click_count: 1 });
    attempts.push({ x: 320, y: OCR_TARGET.y, label: `row-title:${OCR_TARGET.text}@320,${OCR_TARGET.y}`, strategy: "row-title" });
  }
  for (const p of coordCandidates) attempts.push({ x: p.x, y: p.y, label: `coord-scan:${p.x},${p.y}`, strategy: "coord-scan" });

  let last = await ensureTargetPlaying({ np: readNowPlaying(state.text), screenshot: state.screenshot && state.screenshot.url, attempt: "initial", strategy: "initial" });
  let played = last.playing === true;
  let successAttempt = played ? last.attempt : undefined;
  let successX = played ? last.x : undefined;
  let successY = played ? last.y : undefined;
  let strategy = played ? last.strategy : undefined;

  for (const a of attempts) {
    if (played) break;
    const freshState = await sky.get_app_state({ app: APP, disableDiff: true });
    const freshTarget = a.strategy === "ax" ? findResultClickTarget(freshState.text) : null;
    const target = freshTarget ? { element_index: freshTarget.idx, label: `ax:${freshTarget.title}`, strategy: "ax" } : a;
    const r = await tryPlayAt(target);
    last = r;
    if (r.playing === true) {
      played = true;
      successAttempt = r.attempt;
      successX = r.x;
      successY = r.y;
      strategy = r.strategy;
      break;
    }
  }

  nodeRepl.write(JSON.stringify({
    ok: played,
    expected: ARTIST ? `${SONG} - ${ARTIST}` : SONG,
    searchHasSong,
    isResultPage,
    nowPlaying: last.np.line,
    attempts: attempts.map(a => a.label),
    successAttempt,
    successX,
    successY,
    strategy,
    hint: played || isResultPage ? undefined : "搜索后 AX Tree 未识别到结果页，已按 OCR / 坐标扫描降级尝试",
    screenshot: last.screenshot
  }));
}
JS
)
PLAY_JS=${PLAY_JS/__SONG_JSON__/$SONG_JSON}
PLAY_JS=${PLAY_JS/__ARTIST_JSON__/$ARTIST_JSON}
PLAY_JS=${PLAY_JS/__OCR_TARGET_JSON__/$OCR_TARGET_JSON}
PLAY_JS=${PLAY_JS/__AX_PLAY_TARGET_JSON__/$AX_PLAY_TARGET_JSON}
PLAY_JS=${PLAY_JS/__OCR_PLAY_TARGET_JSON__/$OCR_PLAY_TARGET_JSON}
PLAY_OUT=$(bash "$SKILL_ROOT/scripts/exec.sh" -t 60000 "$PLAY_JS" || true)
printf '%s\n' "$PLAY_OUT"
PLAY_JSON=$(printf '%s' "$PLAY_OUT" | python3 -c 'import sys,re; s=sys.stdin.read(); m=re.findall(r"\{.*\}", s, re.S); print(m[-1] if m else "{}")')
PLAY_OK=$(printf '%s' "$PLAY_JSON" | python3 -c 'import json,sys; data=json.loads(sys.stdin.read() or "{}"); print("true" if data.get("ok") is True else "false")')

if [ "$PLAY_OK" != "true" ]; then
  echo "[qqmusic] fallback by menu command..."
  osascript -e "tell application id \"$QQM_BUNDLE\" to activate" \
    -e 'tell application "System Events" to tell process "QQ音乐" to click menu item "播放" of menu "播放控制" of menu bar 1' >/dev/null

  VERIFY_JS=$(cat <<'JS'
{
  const APP = "com.tencent.QQMusicMac";
  const SONG = __SONG_JSON__;
  const ARTIST = __ARTIST_JSON__;
  const wait = ms => new Promise(r => setTimeout(r, ms));
  const readNowPlaying = text => {
    const line = text.split("\n").find(l => /歌曲名：/.test(l) && /歌手名：/.test(l)) || "";
    const m = line.match(/歌曲名：(.+?) - 歌手名：(.+?)(?:\s|$)/);
    return { line: line.trim(), title: m ? m[1].trim() : "", artist: m ? m[2].trim() : "" };
  };
  const matchesTarget = np => {
    if (!np.title || !np.title.includes(SONG)) return false;
    if (ARTIST && np.artist && !np.artist.includes(ARTIST)) return false;
    return true;
  };
  const isPlayingState = text => /按钮\s+暂停|按钮\s+暂停播放|暂停播放/.test(text);
  await wait(1200);
  const state = await sky.get_app_state({ app: APP, disableDiff: true });
  const np = readNowPlaying(state.text);
  nodeRepl.write(JSON.stringify({
    ok: matchesTarget(np) && isPlayingState(state.text),
    expected: ARTIST ? `${SONG} - ${ARTIST}` : SONG,
    nowPlaying: np.line,
    successAttempt: "menu:播放控制/播放",
    strategy: "menu",
    screenshot: state.screenshot && state.screenshot.url
  }));
}
JS
)
  VERIFY_JS=${VERIFY_JS/__SONG_JSON__/$SONG_JSON}
  VERIFY_JS=${VERIFY_JS/__ARTIST_JSON__/$ARTIST_JSON}
  bash "$SKILL_ROOT/scripts/exec.sh" -t 60000 "$VERIFY_JS"
fi
