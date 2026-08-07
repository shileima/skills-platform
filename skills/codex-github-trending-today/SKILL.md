---
name: codex-github-trending-today
description: >
  获取今日 GitHub Trending 热榜并发送本人。当用户说「GitHub 今日热榜」「汇总 GitHub trending」
  「把 GitHub 趋势发给我」「GitHub trending today」等意图时激活。通过 Chrome 打开 github.com，
  依次点击 Open menu → Explore → Trending，汇总前 10 条仓库的名称、Star 数与中文描述，
  并以 Markdown 消息发送到大象桌面客户端登录人本人的单聊会话。
---

# codex-github-trending-today — GitHub 今日热榜汇总并发送本人

通过 Chrome 桌面浏览器访问 GitHub，按 UI 路径进入 **Trending** 页，提取今日前 10 条热榜仓库，整理为 Markdown 摘要（含中文描述），并发送到大象 App (`cn.neixin.pc`) 登录人本人的单聊。

## 依赖

参照 `cua-router-basic` 的 `references/install.md` 与 `references/runtime-exec.md`。执行 sky 操作前必须验证服务在线：

```bash
SKILL_ROOT="${CUA_ROUTER_INSTALL_DIR:-${HOME}/.automan/claude-code-agents/cua-agent/skills/cua-router-basic}"
if [ ! -f "$SKILL_ROOT/SKILL.md" ]; then
  SKILL_ROOT="${HOME}/.cursor/skills/cua-router-basic"
fi
if [ ! -f "$SKILL_ROOT/SKILL.md" ]; then
  SKILL_ROOT="${HOME}/.automan/claude-code-agents/cua-agent/skills/cua-router-basic"
fi
bash "$SKILL_ROOT/scripts/daemon.sh" start
bash "$SKILL_ROOT/scripts/exec.sh" 'nodeRepl.write("ok")'
```

输出 `ok` 后才继续。Chrome 操作遵循 `cua-router-basic` 核心规范：地址栏 `set_value` + `Return`、每次操作后 `get_app_state({ disableDiff: true })`、在完整 `s.text` 上搜索元素。

## 触发判定

- 「GitHub 今日热榜」「GitHub trending today」
- 「汇总 GitHub 趋势 / trending 发给我」
- 「获取 GitHub 热榜并发送本人」

## 稳定流程

1. 启动并验证 `cua-router-basic`。
2. 打开 `https://github.com/`（Chrome 地址栏导航，禁止 `type_text` 输入 URL）。
3. 点击左上角 **Open menu**（AX 中常见 `按钮 Open menu` / `Open global navigation menu`）。
4. 在左侧抽屉菜单点击 **Explore**。
5. 在右侧主题区域点击横向 Tab **Trending**（与 Topics、Collections 同级；**禁止**在地址栏输入 `github.com/trending`）。
6. 从主体区域解析前 **10** 条仓库：`owner/repo`、Star 数（含 today 增量）、英文描述。
7. **Agent 必须将每条英文描述翻译为简洁中文**（保留技术术语时可中英并存），再组装 Markdown。
8. 打开大象 App，进入**客户端登录人**本人单聊，通过 Markdown 编辑器发送摘要。

## 一键执行

推荐分两步（便于 Agent 插入中文翻译）：

```bash
# 1. 抓取 Trending（输出 JSON 到 stdout）
bash "./scripts/fetch-and-send.sh" fetch

# 2. Agent 翻译描述并组装 Markdown 后发送
bash "./scripts/fetch-and-send.sh" send "<登录人姓名>" "<时间标签>" <<'EOF'
【GitHub 今日热榜｜2026-08-04】

1. **owner/repo** ⭐ 12,345（+123 today）
   中文描述…
------------------------------------------------
...
EOF
```

也可合并执行（需预先设置 `SUMMARY_MD` 环境变量为完整 Markdown 正文）：

```bash
SUMMARY_MD="$(cat summary.md)" bash "./scripts/fetch-and-send.sh" all "<登录人姓名>"
```

参数说明：

- **登录人姓名**：大象左侧本人单聊名称（客户端当前登录人，非固定默认值；Agent 从会话上下文或用户指定获取）。
- **时间标签**：默认 `$(date '+%Y-%m-%d %H:%M左右')`。

成功时最后一行输出 JSON，例如：

```json
{"ok":true,"receiver":"张三","repoCount":10,"sentLikely":true}
```

## GitHub 页面操作要点

| 步骤 | AX 搜索关键词 | 降级 |
|------|---------------|------|
| 地址栏 | `地址和搜索栏` / `Address and search bar` | 聚焦后 `Command+L` |
| Open menu | `Open menu` / `Open global navigation menu` | 左上角坐标点击 |
| Explore | `Explore` 链接/按钮 | 抽屉内全文搜索 |
| Trending | `Trending` tab / 链接 | 右侧 Tab 区搜索 |
| 仓库列表 | `article` / `h2` / `star` | 滚动后重新取树 |

解析规则：

- 仓库名：匹配 `owner / repo` 或 `owner/repo` 形式。
- Star：`N stars today`、`star` 数字、或 `k` 后缀（如 `1.2k`）。
- 描述：仓库标题下方第一段非空文本。
- 只取前 10 条；不足 10 条时如实汇报。

## Markdown 摘要格式

```markdown
【GitHub 今日热榜｜YYYY-MM-DD HH:mm左右】

概览：共 10 条 · 语言分布：Python×3、TypeScript×2 …

1. **owner/repo** ⭐ 12,345（+123 today）
   一句话中文描述，说明项目用途。
------------------------------------------------
2. **owner/repo2** ⭐ 8,900（+88 today）
   中文描述…
```

要求：

- 序号 1～10，每条含 **粗体仓库名**、Star 数、**中文描述**。
- 条目之间用 `------------------------------------------------` 分隔。
- 不要输出 AX 前缀（`文本`、`按钮`、`container`）。

## 大象发送

使用公共模块 `dx-send-markdown`（构建后位于 `modules/dx-send-markdown/`）：

```bash
bash "$SKILL_DIR/modules/dx-send-markdown/scripts/send-markdown.sh" \
  "<登录人姓名>" --marker "GitHub 今日热榜" < summary.md
```

开发态未 install 时可回退到仓库 `src/modules/dx-send-markdown/`。发送逻辑详见该模块的 `MODULE.md`。

## 避坑清单

| 陷阱 | 解决 |
|------|------|
| Playwright 占用 Chrome 无窗口 | `preflight-chrome.sh fix` 或 `CUA_ROUTER_CHROME_PREFLIGHT=auto` |
| 未登录 GitHub | Trending 仍可浏览；若页面异常提示用户登录 |
| 描述未译中文 | Agent 在 `send` 前必须翻译，不可直接发英文 |
| 接收人写死 | 必须使用客户端登录人姓名，向用户确认或使用上下文中的本人名称 |
| 复用旧 AX idx | 每次 click 后重新 `get_app_state({ disableDiff: true })` |
| Markdown 按钮找不到 | 先最大化大象窗口再取树 |

## 边界

- 只汇总 **Trending 今日**默认视图（不按语言筛选，除非用户指定）。
- 不 clone 仓库、不打开项目链接、不 star。
- 只发送到本人单聊，不群发。
- 不负责持久化历史榜单。
