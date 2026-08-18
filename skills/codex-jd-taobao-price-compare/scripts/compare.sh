#!/usr/bin/env bash
# 京东 × 淘宝比价 · 一键预热脚本
# 用法：bash scripts/compare.sh "<商品关键词>"
#
# 本脚本只负责：
# 1. 定位并启动 cua-router-basic daemon
# 2. 做 Chrome 预检（Playwright 冲突自动处理）
# 3. 检查 Chrome 是否以 --force-renderer-accessibility 启动，未启动则提示（默认不硬重启，避免误关用户窗口）
# 4. 打印 SKILL_ROOT / QUERY / URLS / 过滤词表供 Agent 后续 exec.sh 内联脚本使用
#
# 复杂的 AX 解析、登录轮询、字段抽取交给 Agent 在 SKILL.md 里编排的
# `bash "$SKILL_ROOT/scripts/exec.sh"` 内联 JS 完成。

set -euo pipefail

QUERY="${1:-}"
INCLUDE_USED="${INCLUDE_USED:-0}"   # 默认只对比全新；置 1 才放行二手/准新
FORCE_A11Y_RESTART="${FORCE_A11Y_RESTART:-0}"  # 置 1 才允许一键重启 Chrome 加 a11y 参数

if [ -z "$QUERY" ]; then
  echo "用法：bash scripts/compare.sh \"<商品关键词>\"" >&2
  echo "  可选环境变量：INCLUDE_USED=1 允许对比二手/准新（默认 0，仅全新）" >&2
  echo "  可选环境变量：FORCE_A11Y_RESTART=1 允许在 AX 不完整时重启 Chrome 加 --force-renderer-accessibility" >&2
  exit 1
fi

resolve_cua_root() {
  local root="${CUA_ROUTER_INSTALL_DIR:-${HOME}/.automan/claude-code-agents/cua-agent/skills/cua-router-basic}"
  if [ ! -f "$root/SKILL.md" ]; then
    root="${HOME}/.cursor/skills/cua-router-basic"
  fi
  if [ ! -f "$root/SKILL.md" ]; then
    root="${HOME}/.automan/claude-code-agents/cua-agent/skills/cua-router-basic"
  fi
  if [ ! -f "$root/SKILL.md" ]; then
    echo "找不到 cua-router-basic 技能，请先安装。参考：" >&2
    echo "  curl -fsSL https://raw.githubusercontent.com/shileima/cua-router-basic/main/scripts/install-remote.sh | bash" >&2
    exit 1
  fi
  printf '%s\n' "$root"
}

url_encode() {
  # POSIX percent-encode（保留 unreserved + 空格转 %20）
  python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1], safe=""))' "$1"
}

parse_target_sku() {
  # 从 query 解析 SKU 维度，输出 JSON 对象（供 Agent 直接使用）
  python3 -c '
import json, re, sys

query = sys.argv[1]

COLOR_ALIASES = {
    "黑色": ["黑色", "疾影黑", "碳晶黑", "黑色钛金属", "深空黑", "曜石黑"],
    "白色": ["白色", "陶瓷白", "白色钛金属", "星光色", "雪域白"],
    "蓝色": ["蓝色", "远峰蓝", "海蓝色", "冰晶蓝"],
    "紫色": ["紫色", "暗紫色", "丁香紫"],
    "金色": ["金色", "沙漠色钛金属", "原色钛金属"],
    "绿色": ["绿色", "苍岭绿", "原野绿"],
    "粉色": ["粉色", "樱花粉"],
    "银色": ["银色", "原色钛金属"],
}

def normalize_storage(s):
    m = re.search(r"(\d+)\s*(GB|TB|G|T)\b", s, re.I)
    if not m:
        return None
    n, u = m.group(1), m.group(2).upper()
    unit = "TB" if u.startswith("T") else "GB"
    return f"{n}{unit}"

storage = normalize_storage(query)
color = None
color_aliases = []
for canonical, aliases in COLOR_ALIASES.items():
    for a in aliases:
        if a in query:
            color = canonical
            color_aliases = aliases
            break
    if color:
        break

variant = None
for v in ["Ultra", "Max", "Plus", "Pro", "SE", "mini"]:
    if re.search(rf"\b{v}\b", query, re.I):
        variant = v
        break

network = None
if re.search(r"WiFi|WIFI|无线局域网", query, re.I):
    network = "WiFi"
elif re.search(r"5G|蜂窝", query):
    network = "蜂窝" if "蜂窝" in query else "5G"

edition = None
for e in ["全新未激活", "国行", "港版", "美版"]:
    if e in query:
        edition = e
        break

# 提取型号：去掉 storage / color 别名 / edition，保留 Pro/Max 等 variant
model = query
if storage:
    model = re.sub(re.escape(storage) + r"|" + re.escape(storage.replace("GB", "G").replace("TB", "T")), " ", model, flags=re.I)
if color_aliases:
    for a in color_aliases:
        model = model.replace(a, " ")
if edition:
    model = model.replace(edition, " ")
model = re.sub(r"\s+", " ", model).strip()

out = {
    "storage": storage,
    "color": color,
    "colorAliases": color_aliases,
    "model": model if model else query,
    "variant": variant,
    "network": network,
    "edition": edition,
}
print(json.dumps(out, ensure_ascii=False))
' "$1"
}

check_chrome_a11y() {
  # 检查 Chrome 是否带 --force-renderer-accessibility 启动
  # 如果没有，且允许自动重启，则重启；否则只提示由 Agent 引导用户
  if pgrep -f "Google Chrome" >/dev/null 2>&1; then
    if pgrep -f -- "--force-renderer-accessibility" >/dev/null 2>&1; then
      echo "chrome_a11y=on"
      return 0
    fi
    if [ "$FORCE_A11Y_RESTART" = "1" ]; then
      echo "[compare.sh] Chrome 未带 --force-renderer-accessibility，正在重启..." >&2
      osascript -e 'tell application "Google Chrome" to quit' >/dev/null 2>&1 || true
      sleep 3
      open -a "Google Chrome" --args --force-renderer-accessibility
      sleep 5
      echo "chrome_a11y=restarted"
      return 0
    fi
    echo "chrome_a11y=off"
    return 0
  fi
  # Chrome 未运行时由后续步骤拉起
  open -a "Google Chrome" --args --force-renderer-accessibility
  sleep 4
  echo "chrome_a11y=freshstart"
}

SKILL_ROOT="$(resolve_cua_root)"
export CUA_ROUTER_CHROME_PREFLIGHT="${CUA_ROUTER_CHROME_PREFLIGHT:-auto}"

bash "$SKILL_ROOT/scripts/daemon.sh" start >/dev/null
bash "$SKILL_ROOT/scripts/exec.sh" 'nodeRepl.write("ok")' >/dev/null
CHROME_A11Y_STATE="$(check_chrome_a11y || true)"

ENCODED="$(url_encode "$QUERY")"
TARGET_SKU="$(parse_target_sku "$QUERY")"
JD_URL="https://search.jd.com/Search?keyword=${ENCODED}&enc=utf-8"
TB_URL="https://s.taobao.com/search?q=${ENCODED}"
# 天猫商城模式 URL（仅在 tab=mall 下搜第三方新机专营店）
TB_MALL_URL="https://s.taobao.com/search?q=${ENCODED}&tab=mall"

cat <<EOF
{
  "ok": true,
  "skillRoot": "$SKILL_ROOT",
  "query": "$QUERY",
  "targetSku": $TARGET_SKU,
  "includeUsed": ${INCLUDE_USED:-0},
  "chromeA11yState": "${CHROME_A11Y_STATE}",
  "urls": {
    "jd": "$JD_URL",
    "taobao": "$TB_URL",
    "taobaoMall": "$TB_MALL_URL",
    "jdHome": "https://www.jd.com/",
    "taobaoHome": "https://www.taobao.com/",
    "appleTmall": "https://apple.tmall.com/"
  },
  "filters": {
    "excludeUsedRegex": "(二手|拍拍|拍拍二手|准新机|95新|99新|9新|A\\\\+|严选|靓机|甄选|官方回收|认证翻新|官翻|后封|展示机|良品|二手买手店)",
    "excludeAccessoriesRegex": "(表带|保护壳|保护套|钢化膜|贴膜|支架|充电线|数据线|手机壳|MagSafe.*保护)",
    "keepBrandNewRegex": "(全新未激活|全新原封|全新原装|未激活国行|官方标配|京东自营|Apple\u4ea7\u54c1\u4eac\u4e1c\u81ea\u8425\u65d7\u8230\u5e97|\u5b98\u65b9\u65d7\u8230\u5e97)"
  },
  "hint": "Agent 现在可以调用 exec.sh 内联 JS 采集。必须先按 targetSku 在两侧详情页点选规格并 verifySelectedSku 通过，再抓价；禁止用天猫默认 SKU 直接比价。默认仅对比全新（excludeUsedRegex 命中的卡片一律剔除，除非 INCLUDE_USED=1）。购买链接必须落到 item.jd.com/{sku}.html 或 detail.tmall.com/item.htm?id=xx&skuId=yy；禁止搜索页 URL。Apple 官方旗舰店无货时用 taobaoMall + 全新未激活国行 关键词兜底。若 chromeA11yState=off，先引导用户重启或让用户执行 FORCE_A11Y_RESTART=1 bash scripts/compare.sh <query>。"
}
EOF
