#!/usr/bin/env bash
# 实时更新页面元素 XPath 缓存
# 用法:
#   bash scripts/update-locators.sh baidu              # 百度首页
#   bash scripts/update-locators.sh baidu-search       # 百度搜索结果页
#   bash scripts/update-locators.sh bilibili

set -euo pipefail

SKILL_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="${1:-}"
URL="${2:-}"

case "$TARGET" in
  baidu)
    python3 "$SKILL_ROOT/scripts/collect-locators.py" --site baidu --page home --url "${URL:-https://www.baidu.com}" --wait 3000
    SLUG="baidu"
    ;;
  baidu-search)
    DEFAULT_SEARCH='https://www.baidu.com/s?ie=utf-8&wd=%E4%BD%A0%E5%A5%BD'
    python3 "$SKILL_ROOT/scripts/collect-locators.py" \
      --site baidu --page search \
      --url "${URL:-$DEFAULT_SEARCH}" \
      --via-search "你好" \
      --wait 5000
    SLUG="baidu-search"
    ;;
  bilibili)
    python3 "$SKILL_ROOT/scripts/collect-locators.py" --site bilibili --page home --url "${URL:-https://www.bilibili.com}" --wait 3000
    SLUG="bilibili"
    ;;
  all-baidu)
    bash "$0" baidu
    bash "$0" baidu-search
    exit 0
    ;;
  "")
    echo "Usage: bash scripts/update-locators.sh <target> [url]"
    echo "  baidu          百度首页"
    echo "  baidu-search   百度搜索结果页（默认 wd=你好）"
    echo "  all-baidu      首页 + 搜索结果页"
    echo "  bilibili       B 站首页"
    echo "  任意站点：bash scripts/update-locators.sh <slug> <url>"
    exit 1
    ;;
  *)
    if [ -z "$URL" ]; then
      echo "Usage: bash update-locators.sh <slug> <url>"
      echo "错误：缺少 URL 参数。请提供目标页面 URL，例如："
      echo "  bash scripts/update-locators.sh mysite https://example.com"
      exit 1
    fi
    python3 "$SKILL_ROOT/scripts/collect-locators.py" --site "$TARGET" --page home --url "$URL" --wait 3000
    SLUG="$TARGET"
    ;;
esac

echo "Done. Cache: reference/locators/${SLUG}.elements.json"
