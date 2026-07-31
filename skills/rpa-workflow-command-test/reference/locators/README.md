# 页面元素定位器缓存

将目标站点**所有可见可定位元素**的 XPath 缓存到本目录，供 bots 工作流指令配置时直接引用。

## 文件约定

| 文件 | 说明 |
|------|------|
| `<site>.elements.json` | **主缓存**（机器可读，含全部元素 XPath） |
| `<site>.md` | 自动生成的可读摘要（按标签分组表格） |

当前站点：

| 站点 | JSON 缓存 | 摘要 | 适用 URL |
|------|----------|------|----------|
| 百度首页 | [baidu.elements.json](./baidu.elements.json) | [baidu.md](./baidu.md) | `https://www.baidu.com/` |
| 百度搜索结果页 | [baidu-search.elements.json](./baidu-search.elements.json) | [baidu-search.md](./baidu-search.md) | `https://www.baidu.com/s?...` |

### 百度：两套搜索框 UI（同一 URL 可能不同）

| UI | 搜索框 | 百度一下按钮 | 何时出现 |
|----|--------|-------------|---------|
| 经典版 | `//*[@id="kw"]` | `//*[@id="su"]` | 部分环境 / 本地 Playwright 采集 |
| 智能输入版（云浏览器） | `//*[@id="chat-textarea"]` | `//*[@id="chat-submit-button"]` | bots 调试，URL 可为 `https://www.baidu.com/` |

**禁止用 URL 判断用哪套 XPath。** 必须在**实际执行环境（云浏览器）** DevTools 探测 `visible:true` 的 id。

采集 JSON 含 `searchVariant` 字段记录**采集环境**所见 variant，不代表 bots 云浏览器一定相同。

## 实时更新

```bash
bash scripts/update-locators.sh baidu              # 百度首页
bash scripts/update-locators.sh baidu-search       # 搜索结果页（首页搜索「你好」进入）
bash scripts/update-locators.sh all-baidu          # 首页 + 搜索结果页
bash scripts/update-locators.sh bilibili           # B 站首页
```

> ⚠️ 百度搜索结果页勿直接打开 `/s?wd=...`（易触发安全验证）。脚本使用 `--via-search` 从首页搜索进入。

Agent 在配置/调试指令前，若缓存超过 7 天或用户要求刷新，**应先执行更新命令**再 Read 对应 JSON。

## 新建 Tab 批量采集（Agent 推荐）

配置工作流前若需 XPath，**不要在工作流 Tab 里导航**。流程见 `reference/element-selector.md` §批量采集：

```
Read 场景 → 列出全部待采元素 → Cmd+T 新建 Tab → 打开目标 URL
→ DevTools 一次性采齐 XPath → 切回工作流 Tab → 逐条填表
```

多页场景在同一探测 Tab 内依次打开各 URL，**一轮采齐**再配置。

## JSON 字段说明

```json
{
  "site": "baidu",
  "url": "https://www.baidu.com/",
  "title": "百度一下，你就知道",
  "collectedAt": "2026-07-29T12:00:00.000Z",
  "elementCount": 42,
  "elements": [
    {
      "tag": "INPUT",
      "id": "kw",
      "name": "wd",
      "type": "text",
      "label": "搜索框可见文本或 #id",
      "xpath": "//input[@id=\"kw\"]",
      "xpathAlt": ["//input[@name=\"wd\"]"],
      "rect": { "x": 0, "y": 0, "width": 100, "height": 40 }
    }
  ]
}
```

## 使用方式

1. Read `reference/locators/<site>.elements.json` 或 `<site>.md`
2. 按 `label` / `id` / `tag` 找到目标元素
3. 复制 `xpath` 填入 bots 指令的「元素选择器」
4. 按 `element-selector.md` C1：若下拉「未找到匹配结果」点 close icon → 等 1s → 点「以 //xxx 为定位器」
5. 有 `xpathAlt` 时可作备选

## 扩展新站点

```bash
bash scripts/update-locators.sh mysite https://example.com
# 生成 reference/locators/mysite.elements.json 与 mysite.md
```

并在 `reference/scenarios/index.md` 中登记新场景。
