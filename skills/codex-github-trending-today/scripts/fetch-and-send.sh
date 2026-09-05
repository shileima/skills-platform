#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-all}"
RECEIVER="${2:-${DAXIANG_RECEIVER:-}}"
TIME_LABEL="${3:-$(date '+%Y-%m-%d %H:%M左右')}"

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

resolve_cua_root() {
  local root="${CUA_ROUTER_INSTALL_DIR:-${HOME}/.automan/claude-code-agents/cua-agent/skills/cua-router-basic}"
  if [ ! -f "$root/SKILL.md" ]; then
    root="${HOME}/.cursor/skills/cua-router-basic"
  fi
  if [ ! -f "$root/SKILL.md" ]; then
    root="${HOME}/.automan/claude-code-agents/cua-agent/skills/cua-router-basic"
  fi
  if [ ! -f "$root/SKILL.md" ]; then
    echo "找不到 cua-router-basic 技能，请先安装" >&2
    exit 1
  fi
  printf '%s\n' "$root"
}

resolve_dx_send_script() {
  local staged="$SKILL_DIR/modules/dx-send-markdown/scripts/send-markdown.sh"
  if [ -f "$staged" ]; then
    printf '%s\n' "$staged"
    return 0
  fi
  local dev="$SKILL_DIR/../../src/modules/dx-send-markdown/scripts/send-markdown.sh"
  if [ -f "$dev" ]; then
    printf '%s\n' "$dev"
    return 0
  fi
  echo "找不到 dx-send-markdown 模块（请 skilldev build/install 或在 skills-platform 仓库内运行）" >&2
  return 1
}

SKILL_ROOT="$(resolve_cua_root)"
bash "$SKILL_ROOT/scripts/ensure-ready.sh" >/dev/null

FETCH_JS="${TMPDIR:-/tmp}/gh-trending-fetch.$$.$RANDOM.mjs"
trap 'rm -f "$FETCH_JS"' EXIT

python3 - "$SKILL_ROOT" > "$FETCH_JS" <<'PY'
import json, sys
from pathlib import Path
skill_root = Path(sys.argv[1])
print(r'''
await (async () => {
  function emitResult(payload) {
    nodeRepl.write(typeof payload === "string" ? payload : JSON.stringify(payload));
  }
  const app = "com.google.Chrome";
  const { execFileSync } = await import("node:child_process");

  function escapeRegExp(text) {
    return String(text).replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&");
  }

  function parseIdx(line) {
    const m = String(line || "").match(/^\s*(\d+)/);
    return m ? parseInt(m[1], 10) : null;
  }

  function findLine(axText, ...patterns) {
    const reList = patterns.map(p => (p instanceof RegExp ? p : new RegExp(p, "i")));
    return axText.split("\n").find(l => reList.every(re => re.test(l))) || null;
  }

  async function getState() {
    return sky.get_app_state({ app, disableDiff: true });
  }

  async function clickLine(line) {
    const idx = parseIdx(line);
    if (idx === null) throw new Error("invalid line idx: " + line);
    await sky.click({ app, element_index: idx });
    await new Promise(r => setTimeout(r, 900));
  }

  function findAddressBarLine(axText) {
    const lines = axText.split("\n");
    return lines.find(l => /\(settable,\s*string\)/.test(l) && /地址和搜索栏|Address and search bar|Omnibox/.test(l))
      || lines.find(l => /\(settable,\s*string\)/.test(l) && /Placeholder:.*网址|Placeholder:.*url/i.test(l))
      || null;
  }

  async function navigate(url) {
    await getState();
    await sky.press_key({ app, key: "Command+l" });
    await new Promise(r => setTimeout(r, 500));
    const s = await getState();
    const addrLine = findAddressBarLine(s.text);
    if (!addrLine) {
      emitResult({ ok: false, error: "address_bar_not_found", preview: s.text.slice(0, 1200) });
      return false;
    }
    const addrIdx = parseIdx(addrLine);
    try {
      await sky.set_value({ app, element_index: addrIdx, value: url });
    } catch (err) {
      emitResult({ ok: false, error: "set_value_failed", detail: String(err), preview: s.text.slice(0, 800) });
      return false;
    }
    await new Promise(r => setTimeout(r, 200));
    await sky.press_key({ app, key: "Return" });
    await new Promise(r => setTimeout(r, 3000));
    return true;
  }

  function findExploreNavLink(axText, label) {
    const re = new RegExp(`link\\s+Description:\\s*${escapeRegExp(label)}\\b`, "i");
    return axText.split("\n").find(l => re.test(l)) || null;
  }

  function findTrendingTabLine(axText) {
    const lines = axText.split("\n");
    const hits = lines.filter(l => /link\s+Description:\s*Trending\b/i.test(l));
    for (const line of hits) {
      const pos = lines.indexOf(line);
      const window = lines.slice(Math.max(0, pos - 10), pos + 6).join("\n");
      if (/Explore navigation|Topics|Collections|Events|GitHub Sponsors/i.test(window)) return line;
    }
    return hits[0] || null;
  }

  async function waitForTrendingTab(maxAttempts = 4) {
    for (let i = 0; i < maxAttempts; i++) {
      const s = await getState();
      const trendingLine = findTrendingTabLine(s.text);
      if (trendingLine) return trendingLine;
      await new Promise(r => setTimeout(r, 1200));
    }
    return null;
  }

  async function ensureTrendingPage() {
    if (!(await navigate("https://github.com/"))) return false;

    let s = await getState();
    const menuLine = findLine(s.text, /Open menu|Open global navigation menu|打开菜单/);
    if (!menuLine) {
      emitResult({ ok: false, error: "open_menu_not_found", preview: s.text.slice(0, 1500) });
      return false;
    }
    await clickLine(menuLine);
    s = await getState();

    const exploreLine = findExploreNavLink(s.text, "Explore");
    if (!exploreLine) {
      emitResult({ ok: false, error: "explore_link_not_found", hint: "请在 GitHub 抽屉菜单中点击 Explore", preview: s.text.slice(0, 1500) });
      return false;
    }
    await clickLine(exploreLine);
    await new Promise(r => setTimeout(r, 2500));

    const trendingLine = await waitForTrendingTab();
    if (!trendingLine) {
      s = await getState();
      emitResult({ ok: false, error: "trending_tab_not_found", hint: "请点击页面横向 Tab「Trending」，禁止在地址栏输入 trending URL", preview: s.text.slice(0, 2000) });
      return false;
    }
    await clickLine(trendingLine);
    await new Promise(r => setTimeout(r, 2000));
    s = await getState();

    if (!/Trending repositories|标题\s+.+\s\/\s.+,\s*Value:/.test(s.text)) {
      emitResult({ ok: false, error: "trending_page_not_ready", preview: s.text.slice(0, 1500) });
      return false;
    }
    return true;
  }

  function extractRepoNameFromLine(line) {
    const raw = String(line || "");
    const heading = raw.match(/标题\s+([^,]+?)\s*,\s*Value:/);
    if (heading) return heading[1].replace(/\s*\/\s*/g, "/").trim();
    const linkDesc = raw.match(/link\s+Description:\s*([^,]+?)\s*,\s*Value:\s*github\.com\/[^/]+\/[^/]+(?:\/|$)/i);
    if (linkDesc) return linkDesc[1].replace(/\s*\/\s*/g, "/").trim();
    return "";
  }

  function parseTrendingRepos(axText, limit = 10) {
    const lines = axText.split("\n");
    const repos = [];
    const seen = new Set();

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      if (!/标题\s+.+\s\/\s.+,\s*Value:/.test(line)) continue;

      const name = extractRepoNameFromLine(line);
      if (!name || seen.has(name)) continue;

      let description = "";
      let starsTotal = "";
      let starsToday = "";
      let language = "";

      for (let j = i + 1; j < Math.min(lines.length, i + 20); j++) {
        const next = lines[j];
        if (/标题\s+.+\s\/\s.+,\s*Value:/.test(next)) break;

        const plain = next.replace(/^\s*\d+\s+(文本|text|链接|link|按钮|button|container|标题)\s+/i, "").trim();
        const starLink = next.match(/link\s+Description:\s*star\s+([\d,]+)/i);
        if (starLink) {
          starsTotal = starLink[1].replace(/,$/, "");
          continue;
        }
        const todayMatch = plain.match(/^([\d,.]+)\s+stars?\s+today$/i);
        if (todayMatch) {
          starsToday = todayMatch[1];
          continue;
        }
        const langMatch = plain.match(/^(TypeScript|Python|Rust|Go|JavaScript|Java|C\+\+|PowerShell|Ruby|Swift|Kotlin|C#|HTML|CSS|Shell|Vue|Dart)$/i);
        if (langMatch) {
          language = langMatch[1];
          continue;
        }
        if (/^Built by|^Spoken language|^Date range|^Fork|^Sponsor|^Star this|^Add this/i.test(plain)) continue;
        if (/^\s*\d+\s+文本\s/.test(next) && plain.length > 20 && !description) {
          description = plain;
        }
      }

      seen.add(name);
      repos.push({
        rank: repos.length + 1,
        name,
        starsTotal: starsTotal || "—",
        starsToday: starsToday || "—",
        language: language || "",
        descriptionEn: description || "（无描述）"
      });
      if (repos.length >= limit) break;
    }
    return repos;
  }

  try {
    execFileSync("/usr/bin/open", ["-a", "Google Chrome"]);
  } catch (_) {}
  await new Promise(r => setTimeout(r, 1000));
  try {
    await getState();
  } catch (err) {
    emitResult({ ok: false, error: "chrome_not_active", detail: String(err) });
    return;
  }

  const ready = await ensureTrendingPage();
  if (!ready) return;

  let s = await getState();
  let repos = parseTrendingRepos(s.text, 10);

  if (repos.length < 5) {
    await sky.press_key({ app, key: "Page_Down" });
    await new Promise(r => setTimeout(r, 800));
    s = await getState();
    repos = parseTrendingRepos(s.text, 10);
  }

  emitResult({
    ok: repos.length > 0,
    repoCount: repos.length,
    pageTitle: (s.text.match(/Window: "([^"]+)"/) || [])[1] || "",
    repos,
    hint: repos.length ? null : "未能从 AX Tree 解析仓库，请确认已通过 Tab 进入 Trending 页"
  });
})()
''')
PY

run_fetch() {
  bash "$SKILL_ROOT/scripts/exec.sh" -t 240000 -f "$FETCH_JS"
}

build_summary_from_json() {
  local json="$1"
  local label="$2"
  python3 - "$json" "$label" <<'PY'
import json, sys
data = json.loads(sys.argv[1])
label = sys.argv[2]
repos = data.get("repos") or []
lines = [f"【GitHub 今日热榜｜{label}】", "", f"概览：共 {len(repos)} 条", ""]
sep = "------------------------------------------------"
for repo in repos:
    stars = repo.get("starsTotal", "—")
    today = repo.get("starsToday", "—")
    today_part = f"（+{today} today）" if today and today != "—" else ""
    lang = repo.get("language")
    lang_part = f" · {lang}" if lang else ""
    desc = repo.get("descriptionZh") or repo.get("descriptionEn") or "（无描述）"
    lines.append(f"{repo.get('rank', '?')}. **{repo.get('name', '?')}** ⭐ {stars}{today_part}{lang_part}")
    lines.append(f"   {desc}")
    lines.append(sep)
if lines and lines[-1] == sep:
    lines.pop()
print("\n".join(lines))
PY
}

run_send() {
  local receiver="$1"
  local summary="$2"
  local send_script
  send_script="$(resolve_dx_send_script)"
  printf '%s' "$summary" | bash "$send_script" "$receiver" --marker "GitHub 今日热榜"
}

case "$MODE" in
  fetch)
    run_fetch
    ;;
  send)
    SUMMARY="$(cat)"
    if [ -z "$SUMMARY" ]; then
      echo '{"ok":false,"error":"empty_summary_on_stdin"}' >&2
      exit 1
    fi
    run_send "$RECEIVER" "$SUMMARY"
    ;;
  all)
    set +e
    FETCH_RESULT="$(run_fetch 2>&1)"
    FETCH_RC=$?
    set -e
    echo "$FETCH_RESULT"
    LAST_LINE="$(printf '%s\n' "$FETCH_RESULT" | tail -n 1)"
    if [ "$FETCH_RC" -ne 0 ]; then
      exit "$FETCH_RC"
    fi
    if ! python3 -c 'import json,sys; d=json.loads(sys.argv[1]); sys.exit(0 if d.get("ok") else 1)' "$LAST_LINE" 2>/dev/null; then
      exit 1
    fi
    if [ -n "${SUMMARY_MD:-}" ]; then
      SUMMARY="$SUMMARY_MD"
    else
      SUMMARY="$(build_summary_from_json "$LAST_LINE" "$TIME_LABEL")"
    fi
    run_send "$RECEIVER" "$SUMMARY"
    ;;
  *)
    echo "Usage: fetch-and-send.sh [fetch|send|all] [receiver] [time_label]" >&2
    exit 1
    ;;
esac
