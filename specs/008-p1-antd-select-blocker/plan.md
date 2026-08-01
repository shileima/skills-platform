# 008-p1-antd-select-blocker · PLAN

## 一、总体思路

把「元素选择器」的输入路径从"运行时在弹框里模拟键盘"迁移到"**预采集 + 平台捕获 / React 原生 setter**"。技术上分三层：

1. **数据层**：让 `collect-locators.py` 支持任意 URL 采集，输出 JSON + Markdown 摘要，agent 直接从 JSON 挑 XPath。
2. **写入层**：新增方式 D（DevTools Console 注入 React `nativeInputValueSetter` + `dispatchEvent('input'/'change')`），专治 AntD Select；同时把方式 B（平台捕获）作为默认。
3. **策略层**：SKILL.md / element-selector.md / ax-verify.md 调整"元素选择器"章节，明确"批量采集 → 方式 B → C1 → D"的三级路径与判定信号。

## 二、具体改动

### 2.1 `scripts/collect-locators.py`

- **兼容当前**：保留百度、B 站的 `searchVariant` 探测和快捷 XPath 输出。
- **新增通用摘要**：`render_markdown` 里，对非 baidu/bilibili 站点，自动挑出：
  - 前 5 个可见 `input` / `textarea`
  - 前 5 个可见 `button`
  - 全部 `[role="search"]`、`[role="searchbox"]`
  - 页面上 `input[type="search"]` / `[aria-label*="搜索"]` / `[placeholder*="搜索"]`
  并列在"快捷 XPath"表格里。
- **新增 CLI 参数**：`--headed` 已存在；补 `--user-data-dir <path>` 可选（复用本地 Chrome 登录态，方便采集需要登录的站点）。
- **异常兜底**：URL 加载超时 / 403 时输出 `warning` 到 JSON 与 Markdown，agent 能识别。

### 2.2 `scripts/update-locators.sh`

- 保留 baidu / baidu-search / all-baidu / bilibili 的 shortcut。
- **通用兜底分支**已存在（`bash scripts/update-locators.sh <slug> <url>`）；补一句 usage 示例，并加参数校验（url 缺失时给出明确报错）。

### 2.3 `reference/element-selector.md`

- **章节顺序调整**：
  1. §批量采集（新建 Tab · 强制）— 前置章节，明确"含元素选择器的指令**必须**先批量采集"
  2. §方式 B：平台「捕获」按钮 — 从中段提到**默认**位置
  3. §方式 C1：pbcopy + 粘贴 + 为定位器 — 标注"AntD Select 环境下常失败"
  4. **§方式 D（新增）：DevTools 注入 React nativeInputValueSetter** — AntD Select 强制触发 onChange
  5. §方式 C2：CSS 属性定义
  6. §方式 A：DevTools 采集（保留作参考）

- **方式 D 内容要点**：
  - 云浏览器 DevTools Console（或本地 Chrome DevTools 对着 bots 配置弹框）执行：
    ```javascript
    (function(xpath){
      const nodes = document.evaluate(
        '//textarea[@class!="hidden"] | //input[not(@type="hidden")] | //*[contains(@class,"ant-select-selection-search-input")]',
        document, null, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null);
      // 找到当前焦点或红框标记的选择器 input
      // 使用 native setter 强制触发 React onChange
      const el = document.activeElement;
      const desc = Object.getOwnPropertyDescriptor(el.tagName === 'TEXTAREA'
        ? HTMLTextAreaElement.prototype
        : HTMLInputElement.prototype, 'value');
      desc.set.call(el, xpath);
      el.dispatchEvent(new Event('input', { bubbles: true }));
      el.dispatchEvent(new Event('change', { bubbles: true }));
    })('//*[@id="chat-textarea"]');
    ```
  - 步骤：click 选择器 input（AX 抓 idx）→ 打开 DevTools（Cmd+Alt+J）→ pbcopy 上面脚本→ Console 粘贴执行→ 关闭 DevTools → 全量抓 AX 验证"该字段是必填字段"已消失 + 出现"为定位器"下拉 → 点定位器 → 保存。
  - **关键点**：脚本必须 target 当前 `document.activeElement`（就是刚点击过的选择器 input），或按 `[class*="ant-select-selection-search-input"]` 精确锚定。

- **方式 B 补强**：明确"断言指令弹框内『捕获』按钮位置 = 元素选择器右侧图标"，并给一个 sky 自动化片段（点击捕获→ 云浏览器切前台→ 用户/agent hover 目标→ 点完成→ AX 验证 XPath 已回填）。

### 2.4 `reference/ax-verify.md`

- Step B 之后新增分支表：

  | 粘贴后 AX 现象 | 下一步 |
  |---------------|--------|
  | value 已含 `//`，且 1s 后见"为定位器" | 继续 Step D 点选，走原 C1 |
  | value 已含 `//`，1s 后**仍**无"为定位器"且见"该字段是必填字段" | **转 element-selector.md §方式 D**，DevTools 注入 setter |
  | value 未粘贴进去（仍空） | 重找 selIdx 或转方式 B（云浏览器捕获） |

- 更新"常见动作 → 成功信号"表：给"AntD Select 输入"单独一行。

### 2.5 `SKILL.md`

- L54–L62 "元素 XPath 批量采集" 章节：
  - 把"任务含 FillText / 点击时"改为"**任务含元素选择器的任意指令（含断言类）时**"；
  - 明确写入路径优先级："**方式 B（平台捕获）** → 方式 C1（粘贴+为定位器）→ 方式 D（React setter 兜底）"；
  - 增加一句"若配置弹框反复出现『该字段是必填字段』，说明当前环境为 AntD Select 阻断，**立即切换到方式 D**"。

### 2.6 场景文件

- `reference/scenarios/baidu.md` / `bilibili.md`：
  - 在"指令节点"表之后追加一节"元素选择器写入策略"，指向 `element-selector.md` §方式 B/C1/D。
  - baidu 场景补一条"若加入 VerifyElementPresent 验证百度按钮"，示例 XPath 直接取自 `locators/baidu.elements.json`。

### 2.7 E2E（`scripts/verify/`）

- 目前项目**没有** `scripts/verify/` 目录，需要新建。
- 新增一个 shell E2E：
  - 用 `scripts/update-locators.sh example https://example.com` 采集一个稳定的公共站；
  - 断言 `reference/locators/example.elements.json` 存在、`elementCount > 0`、`elements[*].xpath` 全部以 `//` 开头；
  - 断言 `reference/locators/example.md` 内含"快捷 XPath"章节且列出至少一个 input 或 button。
- **注意**：这条 E2E 会污染 reference/locators/，跑完必须清理 example.* 文件；测试脚本负责 cleanup。

## 三、模块 / 接口 / 数据

- `collect-locators.py`：新增 `select_quick_elements(elements) -> dict[str, list]`，非 baidu/bilibili 站点使用。
- `render_markdown`：`if site not in ('baidu','bilibili')` 分支渲染通用快捷 XPath。
- `element-selector.md` §方式 D：给两段 JS，一段"当前焦点 input"，一段"按 class 精确锚定的 AntD Select input"。
- `ax-verify.md`：新增一个 axAnalyze 判定辅助 `axSelectStillRequired(lines) => boolean`。

## 四、错误处理

- 采集器 URL 无法加载：写 `warning` 字段到 JSON；`update-locators.sh` 传染性 `exit 2`。
- 方式 D 脚本执行报错：文档要求先 Console `console.log(document.activeElement)` 校验目标；给出常见错误"desc.set is undefined → 目标不是 input/textarea"的解释。

## 五、风险与回滚

- 方式 D 依赖 React 内部约定：文档标注"最后兜底，非推荐"；主推 B。
- 采集脚本改动可能影响百度/B 站现有摘要：改动使用 `if site in ('baidu','bilibili'):` 隔离，通用逻辑走 `else` 分支，兼容为主。
- 回滚：`git revert` 全部提交，退回 C1 主策略。
