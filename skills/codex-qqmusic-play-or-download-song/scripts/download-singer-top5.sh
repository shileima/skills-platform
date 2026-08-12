#!/usr/bin/env bash
# QQ 音乐歌手页热门歌曲前 5 首下载（标准品质，使用客户端官方下载能力）
# 用法：download-singer-top5.sh "歌手名"
# 例：download-singer-top5.sh "毛阿敏"

set -euo pipefail

SINGER="${1:-}"
if [ -z "$SINGER" ]; then
  echo "Usage: $0 <singer>" >&2
  exit 2
fi

# 定位 cua-router-basic
SKILL_ROOT="${CUA_ROUTER_INSTALL_DIR:-${HOME}/.automan/claude-code-agents/cua-agent/skills/cua-router-basic}"
if [ ! -f "$SKILL_ROOT/SKILL.md" ]; then
  SKILL_ROOT="${HOME}/.cursor/skills/cua-router-basic"
fi
if [ ! -f "$SKILL_ROOT/SKILL.md" ]; then
  echo "cua-router-basic not installed. Run its install-remote.sh first." >&2
  exit 1
fi

QQM_BUNDLE="com.tencent.QQMusicMac"

echo "[qqmusic] ensure cua-router..."
bash "$SKILL_ROOT/scripts/daemon.sh" start >/dev/null

echo "[qqmusic] launch app..."
open -b "$QQM_BUNDLE" || {
  echo "QQ Music not installed (bundle=$QQM_BUNDLE)" >&2; exit 1;
}

for i in 1 2 3 4 5 6 7 8; do
  if osascript -e "tell application \"System Events\" to exists (window 1 of process \"QQ音乐\")" 2>/dev/null | grep -q true; then
    break
  fi
  sleep 1
done

echo "[qqmusic] activate app..."
osascript -e "tell application id \"$QQM_BUNDLE\" to activate" >/dev/null
sleep 1

echo "[qqmusic] download top 5 songs for singer: $SINGER"
printf '%s' "$SINGER" | pbcopy
SINGER_JSON=$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1], ensure_ascii=False))' "$SINGER")
JS_CODE=$(cat <<'JS'
{
  const APP = "com.tencent.QQMusicMac";
  const SINGER = __SINGER_JSON__;

  const wait = ms => new Promise(r => setTimeout(r, ms));
  const parseIndex = (text, pattern) => {
    const re = new RegExp(`\\n\\s*(\\d+) ${pattern}`);
    const m = text.match(re);
    return m ? Number(m[1]) : null;
  };

  const clickStandardQuality = async () => {
    const s = await sky.get_app_state({ app: APP, disableDiff: true });
    const standardIdx = parseIndex(s.text, "link 标准品质");
    if (!standardIdx) return false;
    await sky.click({ app: APP, element_index: standardIdx });
    await wait(2200);
    return true;
  };

  const openSingerPage = async () => {
    await sky.click({ app: APP, x: 438, y: 40 });
    await wait(700);
    await sky.press_key({ app: APP, key: "Command+a" });
    await wait(120);
    await sky.press_key({ app: APP, key: "Delete" });
    await wait(120);
    await sky.press_key({ app: APP, key: "Command+v" });
    await wait(700);
    await sky.press_key({ app: APP, key: "Return" });
    await wait(3500);

    // 搜索结果里点击「歌手:张雨生」这一行进入个人页。
    // QQ 音乐搜索浮层 AX 不稳定暴露结果文本，使用已验证区域坐标。
    const candidates = [
      { x: 300, y: 120 },
      { x: 220, y: 120 },
      { x: 300, y: 190 },
      { x: 300, y: 245 },
      { x: 300, y: 300 },
      { x: 360, y: 190 },
      { x: 360, y: 245 },
      { x: 360, y: 300 }
    ];
    const reports = [];
    for (const p of candidates) {
      await sky.click({ app: APP, x: p.x, y: p.y });
      await wait(2500);
      const s = await sky.get_app_state({ app: APP, disableDiff: true });
      const entered = s.text.includes(SINGER) && s.text.includes("热门歌曲") && s.text.includes("singer_detail");
      reports.push({ ...p, entered });
      if (entered) return { ok: true, reports };
    }
    return { ok: false, reports };
  };

  await sky.get_app_state({ app: APP, disableDiff: true });
  await wait(300);

  let state = await sky.get_app_state({ app: APP, disableDiff: true });
  let ready = true;
  let openFailure = null;
  if (!state.text.includes("热门歌曲") || !state.text.includes(SINGER)) {
    const opened = await openSingerPage();
    state = await sky.get_app_state({ app: APP, disableDiff: true });
    ready = opened.ok && state.text.includes("热门歌曲") && state.text.includes(SINGER);
    if (!ready) {
      openFailure = {
        ok: false,
        error: "cannot_open_singer_page",
        hint: `已只搜索「${SINGER}」，但未能自动点击进入「歌手:${SINGER}」个人页。请手动打开歌手页后重试。`,
        reports: opened.reports,
        screenshot: state.screenshot && state.screenshot.url
      };
    }
  }

  if (!ready) {
    nodeRepl.write(JSON.stringify(openFailure));
  } else {

  const findTopSongRows = text => {
    const lines = text.split("\n");
    const rows = [];
    let inHotSongs = false;
    let current = null;

    for (const line of lines) {
      if (/标题 热门歌曲/.test(line)) inHotSongs = true;
      if (inHotSongs && /标题 热门专辑/.test(line)) break;
      if (!inHotSongs) continue;

      const container = line.match(/^\s*(\d+) container (.+?) \d{2}:\d{2}\s*$/);
      if (container) {
        if (current && current.nameIdx && current.downloadIdx) rows.push(current);
        current = { containerIdx: Number(container[1]), title: container[2].trim() };
        continue;
      }
      if (!current) continue;

      const textName = line.match(/^\s*(\d+) (?:文本|text) (.+?)\s*$/);
      if (!current.nameIdx && textName && !/粉丝数|热门歌曲|歌曲|专辑|时长/.test(textName[2])) {
        current.nameIdx = Number(textName[1]);
        current.nameText = textName[2].trim();
      }

      const download = line.match(/^\s*(\d+) link 下载/);
      if (download) current.downloadIdx = Number(download[1]);
    }
    if (current && current.nameIdx && current.downloadIdx) rows.push(current);
    return rows.slice(0, 5);
  };

  let rows = findTopSongRows(state.text);
  if (rows.length < 5) {
    nodeRepl.write(JSON.stringify({
      ok: false,
      error: "cannot_find_top5_download_links",
      foundRows: rows,
      screenshot: state.screenshot && state.screenshot.url
    }));
  } else {

  const results = [];
  for (const row of rows) {
    state = await sky.get_app_state({ app: APP, disableDiff: true });

    // 关键：先点击歌曲名称选中/hover 行，否则下载 icon 可能不可点击。
    await sky.click({ app: APP, element_index: row.nameIdx });
    await wait(700);
    await sky.click({ app: APP, element_index: row.downloadIdx });
    await wait(1200);

    const popup = await sky.get_app_state({ app: APP, disableDiff: true });
    const hasQualityPopup = /标准品质/.test(popup.text);
    const clickedStandard = hasQualityPopup ? await clickStandardQuality() : false;

    results.push({
      nameIdx: row.nameIdx,
      downloadIdx: row.downloadIdx,
      hasQualityPopup,
      clickedStandard
    });

    if (!clickedStandard) {
      await sky.press_key({ app: APP, key: "Escape" });
      await wait(500);
    }
  }

  let finalState = await sky.get_app_state({ app: APP, disableDiff: true });
  const localIdx = parseIndex(finalState.text, "row \\(selectable[^\\n]*\\) 本地");
  if (localIdx) {
    await sky.click({ app: APP, element_index: localIdx });
    await wait(2500);
    finalState = await sky.get_app_state({ app: APP, disableDiff: true });
  }

  const downloadedLine = finalState.text.split("\n").find(l => /已下载歌曲 .*首歌曲/.test(l)) || "";
  const downloadingLine = finalState.text.split("\n").find(l => /正在下载歌曲 .*首歌曲/.test(l)) || "";
  const downloadedSongs = finalState.text.split("\n")
    .filter(l => /text Help:/.test(l))
    .slice(0, 5)
    .map(l => l.trim());

  nodeRepl.write(JSON.stringify({
    ok: true,
    singer: SINGER,
    results,
    downloadedLine: downloadedLine.trim(),
    downloadingLine: downloadingLine.trim(),
    downloadedSongs,
    screenshot: finalState.screenshot && finalState.screenshot.url
  }));
  }
  }
}
JS
)
JS_CODE=${JS_CODE/__SINGER_JSON__/$SINGER_JSON}
bash "$SKILL_ROOT/scripts/exec.sh" -t 180000 "$JS_CODE"
