# 008-p1-antd-select-blocker · SPEC

> **需求 ID**：008
> **优先级**：P1（阻断当前工作流指令测试主链路）
> **关键词**：antd-select、元素选择器、react-onchange、locator-pre-collect、native-input-setter

## 1. 背景与现象

- 项目：`skills-platform` / 技能 `rpa-workflow-command-test`
- 目标平台：`rpa.sankuai.com` / `bots.sankuai.com` — 编排模式工作流
- 症状：在**网页断言**（`VerifyElementPresent`、`VerifyElementVisible`、`VerifyElementAttributeValue`、`VerifyElementHasAttribute`、`VerifyElementNotHasAttribute`、`VerifyElementNotPresent`、`VerifyElementNotVisible` 等，以及 `FillText`、`ClickElementMixed`、`WaitForElement*`、`GetText`、`GetElementAttribute`、`ScrollToElement`、`MouseOver` 等）指令弹框里，**「元素选择器」字段是 AntD Select/Combobox 组件**。它不响应 sky 层模拟出来的键盘事件：
  - `pbcopy + press_key(cmd+v)`：value 显示但底层 React `onChange` 不触发，保存时红字 **「该字段是必填字段」** 始终存在。
  - `sky.type_text`：完成输入但同样红字；且 `[` / `]` / `"` 等 Shift 修饰符字符会被丢字。
  - 双击已保存节点：canvas 是 `contenteditable`，AX 层的 "double click" 只是把光标移到文字里，不触发 React `onDoubleClick`，无法重新进入配置弹框修正。
- **影响面**：所有含"元素选择器"的 UI 指令（≥ 10 条）；用户已经在 8 条断言指令中的 7 条被阻断。

## 2. 根因（Root Cause）

技能当前的默认流程是「**运行时在配置弹框里输入 XPath**」（`reference/element-selector.md` §C1）：粘贴 → 等待 "以 //xxx 为定位器" 下拉 → 点击。这一路径依赖 `press_key(cmd+v)` 或 `type_text` 触发 React 合成事件；但 AntD Select/Combobox 内部只监听 `nativeInputValueSetter` 派发的原生 `input` / `change` 事件，键盘事件不会同步到 React state，`rc-select` 的搜索/选项过滤逻辑因此拿不到用户输入，红字校验也不会消。

派生原因：
- 技能没有把 "**先在系统浏览器批量采集 XPath → 结构化交给 agent → 平台内用『捕获』或原生 setter 落库**" 这条 no-modeled-keyboard 路径作为默认策略；
- `scripts/collect-locators.py` 只把百度、B 站两个内置站点做进了摘要模板，对任意 URL 采集能力弱；
- 「捕获」按钮（`element-selector.md` §方式 B）作为兜底而非默认策略。

## 3. 范围

### 3.1 In Scope

1. **通用元素采集器**：`scripts/collect-locators.py` + `scripts/update-locators.sh` 支持"任意 URL / 任意 slug"即采即缓存，并生成一份对 agent 友好的摘要（自动挑选 input / button / role=search / 常见搜索框）。
2. **AntD Select 兜底写入脚本**：在 `reference/element-selector.md` 中新增 **方式 D：DevTools 注入 React nativeInputValueSetter**，专治 AntD Select/Combobox 无法通过 sky 键盘事件触发 onChange 的场景。
3. **SKILL 默认策略切换**：
   - 把「批量采集」提升为**含元素选择器指令的强制前置步骤**（不再是可选/推荐）；
   - 把「平台『捕获』按钮」（方式 B）设为**元素选择器写入的默认策略**；
   - 把 §C1（粘贴 + 为定位器）降级为**方式 B 不可用时的次选**；
   - 新增方式 D 作为方式 B/C1 都失败时的兜底（用 DevTools Console 注入 native setter 强制触发 React onChange）。
4. **场景层示例更新**：`baidu.md`、`bilibili.md` 中含"元素选择器"的指令，注明"先从 locators/*.elements.json 取 XPath，写入时按方式 B → C1 → D 顺序尝试"。
5. **ax-verify.md**：Step B/C/D 补充"若『该字段是必填字段』在 press_key 后未消失 → 立即转方式 D"的分支。

### 3.2 Out of Scope

- 不改动 `sky.*` 底层实现（这是 cua-router-basic 的范围）。
- 不实现自动的 Chrome extension（方式 D 通过 DevTools Console 手动/半自动执行）。
- 不新增其他生态适配、构建、发布逻辑。
- 不做单元测试 / 集成测试（按项目约束）；仅在 `scripts/verify` 下补充 E2E。

## 4. 验收标准（Definition of Done）

1. `scripts/update-locators.sh <slug> <url>` 对任意 URL 都能产出 `reference/locators/<slug>.elements.json` + `<slug>.md`，摘要能自动列出前若干个 input / button / role=search 元素。
2. `reference/element-selector.md` 存在**方式 D**，包含 DevTools Console 可复制脚本；脚本中使用 `Object.getOwnPropertyDescriptor(HTMLInputElement.prototype,'value').set` + `dispatchEvent(new Event('input',{bubbles:true}))` 触发 React onChange。
3. `SKILL.md` 顶层"元素 XPath 批量采集"章节明确写明"含元素选择器指令 → **必须**先批量采齐 → 优先方式 B（平台捕获）落库 → 失败转 C1/D"。
4. `reference/ax-verify.md` Step D 之后加入判定：若粘贴后 `axAnalyze` 仍见"该字段是必填字段"，直接进入方式 D 分支并给出示例。
5. `scripts/verify/` 下新增或更新 E2E：验证 `update-locators.sh` 对任意 URL 采集流程可跑通（不需要真的连 bots 平台）。
6. `node bin/skilldev.mjs validate` 通过。
7. `dist/` 不手改；技能变更走 `skilldev` 构建（本次 spec 不涉及 `dist/`）。
8. 保留原方式 A / B / C1 / C2 的历史内容，不做破坏性删改，仅调整优先级与新增方式 D。

## 5. 风险与回滚

- **风险**：方式 D 使用了非公开 React 内部约定（`nativeInputValueSetter`），未来 AntD 或 React 内部实现变更可能失效。
- **缓释**：脚本自带 fallback（同时派发 `input` 和 `change` 事件）；文档中标注"若失败，转方式 B 云浏览器捕获"。
- **回滚**：`git revert` 相关 commit；技能仍可用（回到当前 C1 阻断态）。

## 6. 相关文件

- `skills/rpa-workflow-command-test/SKILL.md`
- `skills/rpa-workflow-command-test/reference/element-selector.md`
- `skills/rpa-workflow-command-test/reference/ax-verify.md`
- `skills/rpa-workflow-command-test/reference/scenarios/baidu.md`
- `skills/rpa-workflow-command-test/reference/scenarios/bilibili.md`
- `skills/rpa-workflow-command-test/reference/locators/README.md`
- `skills/rpa-workflow-command-test/scripts/collect-locators.py`
- `skills/rpa-workflow-command-test/scripts/update-locators.sh`
