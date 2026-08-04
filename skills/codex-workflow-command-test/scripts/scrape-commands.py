#!/usr/bin/env python3
"""从官方文档站抓取 UI 指令 reference，写入 reference/commands/。"""

from __future__ import annotations

import os
import re
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from html import unescape
from pathlib import Path

BASE = "https://document.waimai.st.sankuai.com"
SKILL_ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = SKILL_ROOT / "reference" / "commands"


def fetch(slug: str) -> tuple[str, str]:
    url = f"{BASE}/commands/ui-commands/{slug}/"
    with urllib.request.urlopen(url, timeout=20) as resp:
        return slug, resp.read().decode("utf-8", errors="replace")


def parse_table_rows(content: str) -> list[list[str]]:
    rows: list[list[str]] = []
    for row in re.findall(r"<tr>(.*?)</tr>", content, re.S):
        cells = [
            re.sub(r"\s+", " ", unescape(re.sub(r"<[^>]+>", " ", c)).strip())
            for c in re.findall(r"<t[dh][^>]*>(.*?)</t[dh]>", row, re.S)
        ]
        cells = [c for c in cells if c]
        if cells:
            rows.append(cells)
    return rows


def split_io_tables(rows: list[list[str]]) -> tuple[list[list[str]], list[list[str]]]:
    input_rows: list[list[str]] = []
    output_rows: list[list[str]] = []
    current = input_rows
    for row in rows:
        if row[0] in ("参数名", "参数"):
            if input_rows and current is input_rows:
                current = output_rows
            continue
        if len(row) >= 4:
            current.append((row + [""] * 5)[:5])
    return input_rows, output_rows


def extract_xml(codes: list[str], cmd_id: str) -> str | None:
    for code in codes:
        text = unescape(re.sub(r"<[^>]+>", "", code))
        text = text.replace("&lt;", "<").replace("&gt;", ">").replace("&amp;", "&")
        tags = re.findall(r"(<[A-Za-z][A-Za-z0-9]*[^>]*?/>)", text)
        if not tags:
            continue
        for tag in tags:
            if tag.startswith(f"<{cmd_id}"):
                return tag.strip()
        return tags[-1].strip()
    return None


def parse_page(slug: str, html: str) -> dict:
    title_m = re.search(r"<h1[^>]*>([^<]+)</h1>", html)
    title = unescape(title_m.group(1).strip()) if title_m else slug

    meta = re.search(
        r"指令标识：</strong>(.*?)<br>\s*<strong>指令类型：</strong>(.*?)<br>\s*<strong>指令描述：</strong>(.*?)<br>",
        html,
        re.S,
    )
    cmd_id = unescape(meta.group(1).strip()) if meta else slug
    cmd_type = unescape(meta.group(2).strip()) if meta else ""
    desc = unescape(re.sub(r"<[^>]+>", "", meta.group(3)).strip()) if meta else ""

    content_m = re.search(r'class="sl-markdown-content">(.*?)</div>\s*<footer', html, re.S)
    content = content_m.group(1) if content_m else html

    input_rows, output_rows = split_io_tables(parse_table_rows(content))
    codes = re.findall(r"<pre[^>]*><code[^>]*>(.*?)</code></pre>", content, re.S)
    xml = extract_xml(codes, cmd_id)

    notes: list[str] = []
    notes_m = re.search(r'<h2[^>]*id="注意事项"[^>]*>注意事项</h2>(.*?)(?:<h2|$)', content, re.S)
    if notes_m:
        for li in re.findall(r"<li[^>]*>(.*?)</li>", notes_m.group(1), re.S):
            t = unescape(re.sub(r"<[^>]+>", "", li).strip())
            if t:
                notes.append(t)

    return {
        "slug": slug,
        "title": title,
        "cmd_id": cmd_id,
        "cmd_type": cmd_type,
        "desc": desc,
        "input_rows": input_rows,
        "output_rows": output_rows,
        "xml": xml,
        "notes": notes[:5],
        "url": f"{BASE}/commands/ui-commands/{slug}/",
    }


def fmt_table(rows: list[list[str]]) -> str:
    if not rows:
        return "_无_\n"
    lines = [
        "| 参数名 | 类型 | 必填 | 默认值 | 说明 |",
        "|--------|------|------|--------|------|",
    ]
    for row in rows:
        cells = (row + [""] * 5)[:5]
        lines.append("| " + " | ".join(c.replace("|", "\\|") for c in cells) + " |")
    return "\n".join(lines) + "\n"


def render_md(data: dict) -> str:
    required = [r[0] for r in data["input_rows"] if len(r) > 2 and r[2] == "是"]
    req_out = [r[0] for r in data["output_rows"] if len(r) > 2 and r[2] == "是"]

    parts = [
        f"# {data['title']}",
        "",
        f"- **指令标识**：`{data['cmd_id']}`",
        f"- **指令类型**：{data['cmd_type'] or '-'}",
        f"- **官方文档**：{data['url']}",
        f"- **说明**：{data['desc'] or '-'}",
    ]
    if required:
        parts.append(f"- **必填输入参数**：{', '.join(f'`{x}`' for x in required)}")
    if req_out:
        parts.append(f"- **必填输出参数**：{', '.join(f'`{x}`' for x in req_out)}")

    parts += ["", "## 输入参数", "", fmt_table(data["input_rows"]).rstrip()]

    if data["output_rows"]:
        parts += ["", "## 输出参数", "", fmt_table(data["output_rows"]).rstrip()]

    if data["xml"]:
        parts += ["", "## XML 示例", "", "```xml", data["xml"], "```"]

    if data["notes"]:
        parts += ["", "## 注意事项", ""]
        parts.extend(f"- {n}" for n in data["notes"])

    parts.append("")
    return "\n".join(parts)


def write_index(results: list[dict]) -> None:
    web = [d for d in results if "网页" in d["cmd_type"]]
    mobile = [d for d in results if "移动" in d["cmd_type"]]
    other = [d for d in results if d not in web and d not in mobile]

    def lines(items: list[dict]) -> list[str]:
        out: list[str] = []
        for d in sorted(items, key=lambda x: x["title"]):
            req = ", ".join(r[0] for r in d["input_rows"] if len(r) > 2 and r[2] == "是") or "-"
            out.append(
                f"| {d['title']} | `{d['cmd_id']}` | {req} | [{d['slug']}.md]({d['slug']}.md) | {d['url']} |"
            )
        return out

    index = [
        "# Web UI 自动化指令目录",
        "",
        f"共 **{len(results)}** 条 UI 指令，从 [官方文档]({BASE}/) 提取。",
        "",
        "每条 reference 含：**指令标识**、**输入/输出参数**、**必填项**、**XML 示例**（如有）、**注意事项**（如有）。",
        "",
        "配置 bots 指令时，Read 对应 `reference/commands/<slug>.md`，不要全量加载。",
        "",
        "## 网页指令",
        "",
        "| 平台指令名 | 指令标识 | 必填输入参数 | reference | 官方文档 |",
        "|-----------|---------|-------------|-----------|---------|",
        *lines(web),
        "",
        "## 移动端指令",
        "",
        "| 平台指令名 | 指令标识 | 必填输入参数 | reference | 官方文档 |",
        "|-----------|---------|-------------|-----------|---------|",
        *lines(mobile),
    ]

    if other:
        index += [
            "",
            "## 其他指令",
            "",
            "| 平台指令名 | 指令标识 | 必填输入参数 | reference | 官方文档 |",
            "|-----------|---------|-------------|-----------|---------|",
            *lines(other),
        ]

    index += [
        "",
        "## 测试场景常用",
        "",
        "| 指令 | reference |",
        "|------|-----------|",
        "| 打开网页 | [openurl.md](openurl.md) |",
        "| 输入文本 | [filltext.md](filltext.md) |",
        "| 点击元素 | [clickelementmixed.md](clickelementmixed.md) |",
        "",
    ]

    (OUT_DIR / "index.md").write_text("\n".join(index), encoding="utf-8")


def main() -> None:
    with urllib.request.urlopen(f"{BASE}/commands/ui-commands/openurl/", timeout=20) as resp:
        seed = resp.read().decode("utf-8", errors="replace")
    slugs = sorted(set(re.findall(r"/commands/ui-commands/([^/]+)/", seed)))

    pages: dict[str, str] = {}
    with ThreadPoolExecutor(max_workers=8) as pool:
        futures = {pool.submit(fetch, slug): slug for slug in slugs}
        for fut in as_completed(futures):
            slug, html = fut.result()
            pages[slug] = html

    results: list[dict] = []
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for slug in slugs:
        data = parse_page(slug, pages[slug])
        results.append(data)
        (OUT_DIR / f"{slug}.md").write_text(render_md(data), encoding="utf-8")

    write_index(results)
    print(f"Updated {len(results)} commands in {OUT_DIR}")


if __name__ == "__main__":
    main()
