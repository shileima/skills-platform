#!/usr/bin/env python3
"""采集页面可见元素 XPath，写入 reference/locators/<site>.elements.json 并生成 .md 摘要。"""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

from playwright.sync_api import sync_playwright

SKILL_ROOT = Path(__file__).resolve().parents[1]
LOCATORS_DIR = SKILL_ROOT / "reference" / "locators"
COLLECTOR_VERSION = "1.1.0"

DETECT_BAIDU_SEARCH_JS = """
() => {
  function isVisible(el) {
    if (!el) return false;
    const s = window.getComputedStyle(el);
    const r = el.getBoundingClientRect();
    return s.display !== "none" && s.visibility !== "hidden" && s.opacity !== "0"
      && r.width > 0 && r.height > 0;
  }
  const pairs = [
    { variant: "chat-textarea", inputId: "chat-textarea", buttonId: "chat-submit-button" },
    { variant: "kw", inputId: "kw", buttonId: "su" },
  ];
  for (const p of pairs) {
    const input = document.getElementById(p.inputId);
    const button = document.getElementById(p.buttonId);
    if (isVisible(input)) {
      return {
        variant: p.variant,
        inputId: p.inputId,
        buttonId: button && isVisible(button) ? p.buttonId : null,
        inputTag: input.tagName,
        inputXPath: '//*[@id="' + p.inputId + '"]',
        buttonXPath: button && isVisible(button) ? '//*[@id="' + p.buttonId + '"]' : null,
        url: location.href,
        title: document.title,
        wrapperClass: (document.getElementById("wrapper") || {}).className || null,
      };
    }
  }
  return { variant: "unknown", url: location.href, title: document.title };
}
"""

COLLECTOR_JS = """
() => {
  function isVisible(el) {
    if (!el || el.nodeType !== 1) return false;
    const style = window.getComputedStyle(el);
    if (style.display === "none" || style.visibility === "hidden" || style.opacity === "0") return false;
    const rect = el.getBoundingClientRect();
    if (rect.width < 1 || rect.height < 1) return false;
    if (rect.bottom < 0 || rect.right < 0) return false;
    if (rect.top > window.innerHeight || rect.left > window.innerWidth) return false;
    return true;
  }

  function getXPath(el) {
    if (!el || el.nodeType !== 1) return "";
    if (el.id) {
      const id = el.id.replace(/\\\\/g, "\\\\\\\\").replace(/"/g, '\\\\"');
      return "//" + el.tagName.toLowerCase() + '[@id="' + id + '"]';
    }
    if (el.name) {
      const sel = el.tagName.toLowerCase() + '[name="' + el.name.replace(/"/g, '\\\\"') + '"]';
      if (document.querySelectorAll(sel).length === 1) {
        return "//" + sel;
      }
    }
    const parts = [];
    let cur = el;
    while (cur && cur.nodeType === 1 && cur !== document.documentElement) {
      let index = 1;
      let sib = cur.previousElementSibling;
      while (sib) {
        if (sib.tagName === cur.tagName) index++;
        sib = sib.previousElementSibling;
      }
      parts.unshift(cur.tagName.toLowerCase() + "[" + index + "]");
      cur = cur.parentElement;
      if (parts.length > 8) break;
    }
    return "/" + parts.join("/");
  }

  function getAltXPaths(el, primary) {
    const alts = [];
    const tag = el.tagName.toLowerCase();
    if (el.id) alts.push('//*[@id="' + el.id.replace(/"/g, '\\\\"') + '"]');
    if (el.name) alts.push("//" + tag + '[@name="' + el.name.replace(/"/g, '\\\\"') + '"]');
    const cls = (el.className || "").toString().trim().split(/\\s+/).filter(Boolean)[0];
    if (cls) alts.push("//" + tag + '[contains(@class,"' + cls.replace(/"/g, '\\\\"') + '")]');
    const text = (el.innerText || el.textContent || "").trim().replace(/\\s+/g, " ").slice(0, 30);
    if (text && !/[<>]/.test(text)) {
      alts.push("//" + tag + '[normalize-space(.)="' + text.replace(/"/g, '\\\\"') + '"]');
    }
    return [...new Set(alts)].filter(x => x !== primary).slice(0, 3);
  }

  function labelOf(el) {
    const text = (el.innerText || el.textContent || "").trim().replace(/\\s+/g, " ").slice(0, 60);
    if (text) return text;
    if (el.getAttribute("aria-label")) return el.getAttribute("aria-label").slice(0, 60);
    if (el.getAttribute("placeholder")) return el.getAttribute("placeholder").slice(0, 60);
    if (el.getAttribute("alt")) return el.getAttribute("alt").slice(0, 60);
    if (el.id) return "#" + el.id;
    if (el.name) return "@" + el.name;
    return el.tagName.toLowerCase();
  }

  const selector = [
    "a", "button", "input", "textarea", "select", "label", "img",
    "h1", "h2", "h3", "h4", "h5", "h6",
    '[role="button"]', '[role="link"]', '[role="tab"]', '[role="menuitem"]',
    "[onclick]", "[id]", "video", "summary"
  ].join(",");

  const seen = new Set();
  const elements = [];

  for (const el of document.querySelectorAll(selector)) {
    if (!isVisible(el)) continue;
    const xpath = getXPath(el);
    if (!xpath || seen.has(xpath)) continue;
    seen.add(xpath);

    const rect = el.getBoundingClientRect();
    elements.push({
      tag: el.tagName,
      id: el.id || "",
      name: el.name || "",
      type: el.type || "",
      role: el.getAttribute("role") || "",
      class: (el.className || "").toString().slice(0, 100),
      placeholder: el.getAttribute("placeholder") || "",
      ariaLabel: el.getAttribute("aria-label") || "",
      href: el.getAttribute("href") || "",
      label: labelOf(el),
      xpath,
      xpathAlt: getAltXPaths(el, xpath),
      rect: {
        x: Math.round(rect.x),
        y: Math.round(rect.y),
        width: Math.round(rect.width),
        height: Math.round(rect.height),
      },
    });
  }

  elements.sort((a, b) => a.rect.y - b.rect.y || a.rect.x - b.rect.x);

  return {
    url: location.href,
    title: document.title,
    collectedAt: new Date().toISOString(),
    viewport: { width: window.innerWidth, height: window.innerHeight },
    userAgent: navigator.userAgent,
    elementCount: elements.length,
    elements,
  };
}
"""


def cache_slug(site: str, page: str = "home") -> str:
    return site if page in ("", "home") else f"{site}-{page}"


def render_markdown(cache: dict) -> str:
    slug = cache["cacheSlug"]
    page = cache.get("page", "home")
    update_cmd = f"bash scripts/update-locators.sh {slug}" if page != "home" else f"bash scripts/update-locators.sh {cache['site']}"
    if page != "home":
        update_cmd = f"bash scripts/update-locators.sh {cache['site']}-{page}"

    title_suffix = {"home": "首页", "search": "搜索结果页"}.get(page, page)
    lines = [
        f"# {cache['site']} {title_suffix} — 元素定位器缓存",
        "",
        f"> **自动生成**，请勿手改。更新：`{update_cmd}`",
        "",
        "## 缓存信息",
        "",
        "| 项 | 值 |",
        "|----|-----|",
        f"| 站点 | {cache['site']} |",
        f"| 页面 | {page} |",
        f"| URL | {cache['url']} |",
        f"| 标题 | {cache['title']} |",
        f"| 采集时间 | {cache['collectedAt']} |",
        f"| 元素数量 | {cache['elementCount']} |",
        f"| 采集器版本 | {cache['collectorVersion']} |",
        f"| 完整数据 | [{slug}.elements.json](./{slug}.elements.json) |",
        "",
    ]
    if cache.get("warning"):
        lines += [f"> ⚠️ {cache['warning']}", ""]

    lines += ["## 快捷 XPath", ""]

    def pick(pred):
        for el in cache["elements"]:
            if pred(el):
                return el
        return None

    def best_xpath(el: dict) -> str:
        """优先返回 xpathAlt 中的 //*[@id=...] 通用形式（若存在）。"""
        el_id = el.get("id")
        if el_id:
            universal = f'//*[@id="{el_id}"]'
            for alt in el.get("xpathAlt") or []:
                if alt == universal:
                    return alt
        return el["xpath"]

    # 按页面类型选搜索框，避免跨页混用（首页 kw / 结果页 chat-textarea）
    if page == "search":
        search_input = (
            pick(lambda e: e.get("id") == "chat-textarea")
            or pick(lambda e: e.get("tag") == "TEXTAREA" and e.get("id"))
        )
        search_btn = (
            pick(lambda e: e.get("id") == "chat-submit-button")
            or pick(lambda e: e.get("tag") == "BUTTON" and "submit" in e.get("id", ""))
        )
    else:
        search_input = (
            pick(lambda e: e.get("id") == "kw")
            or pick(lambda e: e.get("type") == "text" and e.get("name") == "wd")
        )
        search_btn = pick(lambda e: e.get("id") == "su") or pick(lambda e: e.get("type") == "submit")

    if search_input:
        lines.append(f"- **搜索框**：`{best_xpath(search_input)}`")
        if best_xpath(search_input) != search_input["xpath"]:
            lines.append(f"  - 标签限定 XPath：`{search_input['xpath']}`")
    if search_btn:
        lines.append(f"- **搜索按钮**：`{best_xpath(search_btn)}`")
        if best_xpath(search_btn) != search_btn["xpath"]:
            lines.append(f"  - 标签限定 XPath：`{search_btn['xpath']}`")

    sv = cache.get("searchVariant") or {}
    if sv.get("variant") and sv["variant"] != "unknown":
        lines += [
            "",
            f"> **本环境采集探测**：variant=`{sv['variant']}`，input=`{sv.get('inputId')}`，wrapper=`{sv.get('wrapperClass', '-')}`",
        ]

    # 页面适用说明（防止跨页误用 XPath）
    if cache.get("site") == "baidu":
        if page == "home":
            lines += [
                "",
                "> **适用 URL**：`https://www.baidu.com/`（标题「百度一下，你就知道」）",
                "> ⚠️ **同一 URL 存在两种 UI**：",
                "> - 经典版：`input#kw` + `input#su`",
                "> - 智能输入版：`textarea#chat-textarea` + `button#chat-submit-button`",
                "> **云浏览器（bots 调试）与本地 Playwright 可能不同**。配置 FillText 前必须在**云浏览器 DevTools** 探测可见输入框，**禁止仅凭 URL 或缓存文件名断定**。",
                "> 探测命令见 `reference/element-selector.md` §百度搜索框探测。",
            ]
        elif page == "search":
            lines += [
                "",
                "> **适用 URL**：`https://www.baidu.com/s?...`（搜索结果页）",
                "> 通常为 `textarea#chat-textarea`；若仍为 `kw` 则以云浏览器探测为准。",
            ]

    if page == "search":
        first_result = pick(lambda e: e.get("tag") == "H3" and e.get("xpath"))
        if not first_result:
            first_result = pick(lambda e: "result" in e.get("class", "").lower() or "c-container" in e.get("class", ""))
        if first_result:
            lines.append(f"- **首条结果区域**：`{first_result['xpath']}`")
        next_page = pick(lambda e: "下一页" in e.get("label", "") or e.get("class") == "n")
        if next_page:
            lines.append(f"- **下一页**：`{next_page['xpath']}`")

    lines.append("")

    groups: dict[str, list] = {}
    for el in cache["elements"]:
        groups.setdefault(el["tag"], []).append(el)

    lines += ["## 全部可见元素（按标签分组）", ""]
    for tag in sorted(groups):
        lines += [f"### {tag} ({len(groups[tag])})", "", "| 标签/文本 | id | name | XPath |", "|----------|-----|------|-------|"]
        for el in groups[tag]:
            label = (el.get("label") or "").replace("|", "\\|")[:40]
            lines.append(f"| {label} | {el.get('id') or '-'} | {el.get('name') or '-'} | `{el['xpath']}` |")
        lines.append("")

    return "\n".join(lines)


def baidu_search_via(page_obj, query: str, wait_ms: int) -> None:
    """按当前页面可见控件执行搜索（自动识别 kw 或 chat-textarea）。"""
    variant = page_obj.evaluate(DETECT_BAIDU_SEARCH_JS)
    if variant.get("variant") == "chat-textarea":
        page_obj.fill("#chat-textarea", query)
        if variant.get("buttonId"):
            page_obj.click(f"#{variant['buttonId']}")
        else:
            page_obj.keyboard.press("Enter")
    elif variant.get("variant") == "kw":
        page_obj.fill("#kw", query)
        page_obj.click("#su")
    else:
        raise RuntimeError(f"未识别百度搜索控件: {variant}")
    page_obj.wait_for_timeout(max(wait_ms, 5000))


def collect(
    site: str,
    url: str,
    page: str = "home",
    headless: bool = True,
    wait_ms: int = 3000,
    via_search: str | None = None,
) -> dict:
    LOCATORS_DIR.mkdir(parents=True, exist_ok=True)
    slug = cache_slug(site, page)
    search_variant = None

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=headless, channel="chrome")
        try:
            context = browser.new_context(viewport={"width": 1440, "height": 900}, locale="zh-CN")
            page_obj = context.new_page()

            if via_search and site == "baidu":
                page_obj.goto("https://www.baidu.com", wait_until="domcontentloaded", timeout=60000)
                page_obj.wait_for_timeout(2000)
                baidu_search_via(page_obj, via_search, wait_ms)
            else:
                page_obj.goto(url, wait_until="domcontentloaded", timeout=60000)
                page_obj.wait_for_timeout(wait_ms)

            title = page_obj.title()
            body = page_obj.content()
            warning = None
            if any(k in title for k in ("安全验证", "百度验证")) or "网络不给力" in body:
                warning = "可能触发百度安全验证，缓存不完整；请用 --via-search 或已登录 Chrome 重新采集"
            raw = page_obj.evaluate(COLLECTOR_JS)
            search_variant = None
            if site == "baidu":
                search_variant = page_obj.evaluate(DETECT_BAIDU_SEARCH_JS)
        finally:
            browser.close()

    cache = {
        "site": site,
        "page": page,
        "cacheSlug": slug,
        "collectorVersion": COLLECTOR_VERSION,
        **raw,
    }
    if via_search:
        cache["searchQuery"] = via_search
    if search_variant:
        cache["searchVariant"] = search_variant
    if warning:
        cache["warning"] = warning

    json_path = LOCATORS_DIR / f"{slug}.elements.json"
    md_path = LOCATORS_DIR / f"{slug}.md"
    json_path.write_text(json.dumps(cache, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    md_path.write_text(render_markdown(cache), encoding="utf-8")

    print(f"Updated {json_path} ({cache['elementCount']} elements)")
    print(f"Updated {md_path}")
    if warning:
        print(f"WARNING: {warning}")
    return cache


def main() -> None:
    parser = argparse.ArgumentParser(description="Collect visible element XPaths for a page")
    parser.add_argument("--site", required=True)
    parser.add_argument("--url", required=True)
    parser.add_argument("--page", default="home", help="home | search | custom slug suffix")
    parser.add_argument("--via-search", default=None, help="从首页输入关键词搜索后采集（避免直接打开 /s? 触发验证）")
    parser.add_argument("--headed", action="store_true")
    parser.add_argument("--wait", type=int, default=3000)
    args = parser.parse_args()
    headless = not args.headed and args.via_search is None
    collect(
        args.site,
        args.url,
        page=args.page,
        headless=headless,
        wait_ms=args.wait,
        via_search=args.via_search,
    )


if __name__ == "__main__":
    main()
