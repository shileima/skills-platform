---
name: codex-workflow-command-test
description: >
  Bots 平台编排模式工作流指令配置与调试技能。当用户在对话中表达以下意图时激活：
  「在 bots 上新建编排模式工作流」「bots 工作流加指令」「配置 bots 自动化流程」
  「bots 编排模式添加打开网页/输入文本/点击指令」「bots 工作流调试」「bots 调试报错修复」
  「RPA 工作流测试」「rpa.sankuai.com 工作流」「bots.sankuai.com 工作流」「bots 指令配置」「bots 元素选择器」
  「bots 捕获元素」「bots 云浏览器采集」「bots 调试运行」「编排模式指令测试」
  「百度场景测试」「bilibili 场景测试」「B站工作流测试」
  「网页断言测试」「验证元素存在/可见/属性/不存在」「验证文本存在/不存在」「断言指令批量回归」
  「上传文件指令测试」「UploadFileFromS3」「input[type=file] 测试」「图片上传组件测试」「附件上传指令」
  「循环遍历元素」「LoopElements」「小红书循环」「outputList 测试」「@{toolId.index}」「批量抓取标题」
  「sogou场景」「搜狗工作流测试」
  「workflow command test」「bots workflow debug」「add instruction to bots workflow」。
  未指定场景/指令时默认 B站四步（打开网页→输入文本→点击→刷新网页），直接开始、禁止询问。内置场景含百度/B站/断言/上传/LoopElements。指令文档 https://document.waimai.st.sankuai.com/
  底层工具：cua-router-basic skill（sky.* API 操作 Chrome）。执行前必须先确认 cua-router-basic 已安装就绪。
  详细步骤在 reference/ 目录，按模块按需 Read，不要一次性加载全部 reference。
  不要把"查 bots 平台文档""普通网页浏览""代码 review"误进入；本技能只负责在
  bots.sankuai.com 编排模式工作流中添加、配置、调试 web 自动化指令这一件事。
  测试前提：rpa 新建空编排工作流 → 按序加指令 → 配表单保存 → 检查 → 调试 → 查日志与 icon → 修复。
---

# Bots 编排模式工作流指令测试

在 rpa.sankuai.com（或 bots 空间）**空编排工作流**中，按顺序添加待测指令、完善表单配置、调试运行，并根据**聊天区日志**、**编排区执行/配置警示** 修复，直到全部通过。

- **底层工具**：cua-router-basic（`sky.*` API）
- **指令官方文档**：https://document.waimai.st.sankuai.com/
- **详细模块**：本目录 `reference/` 下，**按需 Read，勿全量加载**

## 测试前提（必读）

完整流程见 **[reference/test-workflow.md](reference/test-workflow.md)**：

1. 打开 **rpa.sankuai.com 首页** → 左侧点击「**工作流**」→ 新建**空**编排模式工作流
2. 在编排区**按顺序**添加待测指令（`insert-command.md`）：**首条**选中**开始节点 → Enter** 在开始节点下方空行插入；**向后追加**选中锚点指令（通常为上一条/最后一条）→ Enter 空行 → 搜索+双击；**禁止**从结束节点上方起建、禁止拖拽提示行、禁止无锚点插入；插入后**必须**校验新节点在锚点**之后**（见 `insert-command.md` §插入后强制核对）
3. 逐条**完善表单并保存**（保存前必验：弹框 label 前红色 `*` 为必填；**条件必填**须对照 `commands/<slug>.md`「设置方式 → 对应必填字段」，见 `test-workflow.md` §3、`platform-ops.md` §2.4），保存报错当场修复
4. **每条保存后**：点顶部「**检查**」→ 下拉无「配置异常节点 / 节点配置不完整」、按钮无红色数字 badge（见 `test-workflow.md` §保存后配置校验）
5. **调试前**：场景顺序终检 + 编排区每条指令**右侧**无配置警示 icon（见 `test-workflow.md` §调试前配置终检、`debug.md` §调试前置）
6. **调试** → 弹框**直接运行**（无需配置弹框，默认「随机设备」）
7. 执行后检查：**聊天区调试日志** + 编排区**左侧**执行 icon + **右侧**配置 icon + 「检查」面板（见 `test-workflow.md` §第 5 步）
8. 根据报错修复；同一指令多次失败 → **删除并在原位置重插、重配表单**
9. 直到聊天区无报错、编排区无配置/执行警示、且「检查」无异常

## 无报错即调试（强制 · 禁止询问）

配置与终检全部通过后，**下一动作必须是「调试 → 运行」**，不得停顿、不得向用户确认。

### 调试门控（全部满足 → 立即调试）

| # | 条件 | 不通过时 |
|---|------|---------|
| 1 | `prerequisites.md` 验证输出 `ok` | 先装/启 cua-router |
| 2 | 场景全部指令已保存 | 继续配表保存 |
| 3 | 「检查」无 badge、无「节点配置不完整」 | 双击修复 → 再检查 |
| 4 | 调试前顺序终检 `readyForDebug: true` | 调序后重检 |
| 5 | 调试前配置终检 `readyForDebug: true` | 补配置后重检 |
| 6 | AX / 聊天区 / 保存弹框**无任何报错文案** | 先修复，禁止带错调试 |

**满足 1–6 → 同一轮 automation 内连续执行**：点「调试」→ 弹框直接点「运行」（默认随机设备）→ 等待执行 → 四处扫描。禁止在步骤 5 与调试之间插入用户交互。

### 禁止行为

- **禁止**问用户「是否继续调试」「需要我帮你运行吗」「要不要收尾」
- **禁止**终检已通过却输出「建议手动调试」而不执行 sky 调试脚本
- **禁止**以「部分完成」「遇阻」为由跳过调试——应修复阻塞项后继续，而非停下来询问
- 响应末尾**禁止**附带确认式追问；仅当**硬阻塞**（平台不可达、依赖未安装、需用户登录/VNC）才报告阻塞原因

详见 `reference/test-workflow.md` §无报错即调试门控、`reference/debug.md` §调试运行。

## 元素查找降级顺序（强制）

所有 sky 点击/双击/验证目标元素时，必须遵循 `cua-router-basic` 的三级定位策略：

1. **AX Tree 找元素**：全量 `get_app_state({ disableDiff:true })`，在完整 AX Tree 上用结构化信号、关键词、`findIdx` / `findAllIdx` 定位，命中后用 `element_index` 操作。
2. **AX 找不到时 OCR 定位**：如果截图中目标可见但 AX Tree 没暴露元素，读取 `s.screenshot.url`，用 macOS Vision OCR / 视觉识别定位目标文案或图标中心坐标后点击。
3. **OCR 失败再坐标扫描**：只在 OCR 也失败时，使用已校准的一组候选坐标按优先级尝试；禁止只用单个硬编码坐标。
4. **每次点击后重新抓 AX Tree 验证**：成功后停止后续 attempts；失败才进入下一候选。

每次自动化脚本输出必须包含定位策略字段，便于排查与沉淀：

```json
{
  "successAttempt": "ax:<label> | ocr:<text>@<x>,<y> | coord-scan:<x>,<y>",
  "successX": 344,
  "successY": 393,
  "strategy": "ax | ocr | coord-scan"
}
```

## 配置校验三条硬规则

平台有两套独立警示，**不可只查左侧执行 icon**：

| # | 时机 | 检查什么 | 通过标准 |
|---|------|---------|---------|
| 1 | **每条指令保存后** | 点顶部「检查」→ 读下拉 | 无「配置异常节点」、无「节点配置不完整」文案；「检查」按钮无红色数字 badge |
| 2 | **点「调试」前** | 编排区每条指令**右侧** | 无红色 ⓘ /「节点配置不完整」类配置警示（与左侧 ✅/❌ 执行结果无关） |
| 3 | **保存前（条件必填）** | Read `commands/<slug>.md` | 按「设置方式」等枚举值核对**条件必填**（如 SetCookie 的 Domain/URL）；不能只看弹框 `*` 与红框 |

sky 自动化脚本见 `test-workflow.md` §保存后配置校验、§调试前配置终检、`debug.md` §配置校验 sky 脚本。

## 元素 XPath 批量采集（含元素选择器的任意 UI 指令——强制前置）

> 🚫 **强制前置**：任务含元素选择器的**任意** UI 指令（含 FillText、点击、断言类、等待类等所有需「元素选择器」字段的指令），**必须**在配表单之前完成批量采集。

1. Read `scenarios/<场景>.md` → 列出全部待采元素
2. 按 **`element-selector.md` §批量采集（新建 Tab · 强制前置）**：**Cmd+T 新建 Tab** → 打开目标页 → DevTools **一次性采齐**本任务 XPath → 切回工作流 Tab
3. 再进入编排区逐条填表、保存

**XPath 写入策略优先级**：**方式 C（pbcopy + Cmd+V 粘贴 XPath + Enter，默认）** → **方式 B（平台捕获，退而求其次）**。配置弹框出现「该字段是必填字段」时，务必在 Cmd+V 后立即按 Enter；两种方式**都不生效**时刷新页面重开配置弹框重试，**禁止**其他手工写入方式（如点击「以…为定位器」下拉、DevTools React setter、type_text、set_value 直写、CSS 属性定义）。

> ⚠️ **禁止**在工作流 Tab 地址栏导航探测；**禁止**配一条指令采一条——应预先批量采集。

## 默认场景（无用户输入时）

用户仅激活本技能、**未指定测试场景或测试指令**时：

- **禁止**向用户询问场景、指令列表或工作流名称
- **直接** Read `reference/scenarios/bilibili.md` 并按默认四步执行：**打开网页 → 输入文本 → 点击元素 → 刷新网页**
- 工作流名称可用 `Bilibili搜索测试-YYYYMMDD`；仅当用户显式给出名称时才改用用户名称
- 验证依赖就绪后**立即**进入 platform-ops / test-workflow，不要等待用户确认

## 执行流程

```
1. reference/prerequisites.md       ← cua-router-basic 安装验证
2. reference/ax-verify.md         ← 动作后全量 AX 验证；AX → OCR → 坐标扫描三级定位（sky 操作必遵）
3. reference/test-workflow.md       ← 测试标准流程（新建→加指令→调试→修复）
4. reference/scenarios/<场景>.md    ← 测试场景与指令顺序（未指定 → bilibili.md）
5. reference/element-selector.md  ← 需 XPath 时：§批量采集（新建 Tab）采齐全部元素
6. reference/locators/<site>.*      ← 元素 XPath 缓存（可选，优先 Read）
7. reference/commands/<指令>.md     ← 单条指令参数
8. reference/url-input.md           ← 填「网址」等 URL 字段时必读
9. reference/debug.md               ← 报错修复与重插策略
```

> ⚠️ **硬性前置**：未完成 `prerequisites.md` 且验证输出 `ok` 前，**不得**调用 `sky.*` 或操作 bots 平台。

## Reference 模块索引

Reference 文件位于本技能目录下的 `reference/`，与 `SKILL.md` 同级。执行时用 Read 工具读取对应路径。

| 模块 | 文件 | 何时 Read |
|------|------|----------|
| 前置依赖 | [reference/prerequisites.md](reference/prerequisites.md) | **每次执行最先** |
| **AX 步骤验证** | [reference/ax-verify.md](reference/ax-verify.md) | **每次 sky 操作必遵** |
| **测试标准流程** | [reference/test-workflow.md](reference/test-workflow.md) | **每次测试必读** |
| 平台操作 | [reference/platform-ops.md](reference/platform-ops.md) | 新建工作流、canvas 双击、保存前校验 |
| 指令目录（98 条 UI 指令） | [reference/commands/index.md](reference/commands/index.md) | 查找/确认任意 UI 指令参数 |
| 单条指令 | `reference/commands/<slug>.md` | 配置具体指令节点时按需 Read |
| **捕获元素** | [reference/capture-element.md](reference/capture-element.md) | **需通过平台「捕获」按钮采集元素时**：6 步捕获流程、多信号判据 |
| 元素选择器 | [reference/element-selector.md](reference/element-selector.md) | **需 XPath 时**：§批量采集（新建 Tab）一次性采齐；**首选**方式 C（pbcopy + Cmd+V + Enter）；连续失败转方式 B（Read `capture-element.md`） |
| **URL 输入规范** | [reference/url-input.md](reference/url-input.md) | 填「网址」等 URL 字段时**必读**（禁止 type_text） |
| **插入指令** | [reference/insert-command.md](reference/insert-command.md) | **需在编排区 canvas 中追加指令时**：插入位置约束、光标定位、搜索+双击、右键菜单调序、插入后强制核对 |
| 调试修复 | [reference/debug.md](reference/debug.md) | 保存后调试、报错修复 |
| 场景索引 | [reference/scenarios/index.md](reference/scenarios/index.md) | 选择测试场景 |
| 元素定位器缓存 | [reference/locators/README.md](reference/locators/README.md) | 了解缓存机制 |
| 百度首页 XPath | [reference/locators/baidu.elements.json](reference/locators/baidu.elements.json) | 百度首页元素 |
| 百度搜索结果 XPath | [reference/locators/baidu-search.elements.json](reference/locators/baidu-search.elements.json) | 百度搜索结果页（wd=你好） |
| 百度场景 | [reference/scenarios/baidu.md](reference/scenarios/baidu.md) | 用户说「百度」 |
| **百度断言批量场景**（9 条网页断言） | [reference/scenarios/baidu-assertions.md](reference/scenarios/baidu-assertions.md) | 用户说「网页断言测试」「验证元素/文本 xxx」「断言批量回归」 |
| **上传文件专项场景**（`UploadFileFromS3`） | [reference/scenarios/upload-file.md](reference/scenarios/upload-file.md) | 用户说「上传文件指令测试」「UploadFileFromS3」「图片上传组件」「input[type=file] 测试」 |
| **循环遍历元素场景**（`LoopElements` · 小红书首页） | [reference/scenarios/loop-elements-xhs.md](reference/scenarios/loop-elements-xhs.md) | 用户说「循环遍历元素」「LoopElements」「小红书循环」「outputList」「批量抓取标题」 |
| **B站场景（默认）** | [reference/scenarios/bilibili.md](reference/scenarios/bilibili.md) | 用户说「bilibili/B站」；**未指定场景/指令时自动使用** |
| **搜狗场景** | [reference/scenarios/sogou.md](reference/scenarios/sogou.md) | 用户说「sogou/搜狗」；四步：打开网页→输入文本→点击→刷新 |

### 扩展 / 更新 reference

**UI 指令**（98 条）：官方文档变更后运行 `python3 scripts/scrape-commands.py`

**页面元素 XPath 缓存**（实时更新）：

```bash
bash scripts/update-locators.sh baidu              # 百度首页
bash scripts/update-locators.sh baidu-search       # 百度搜索结果页（via-search，避免安全验证）
bash scripts/update-locators.sh all-baidu            # 两者一起更新
bash scripts/update-locators.sh bilibili
python3 scripts/collect-locators.py --site baidu --page search --via-search "你好" --url "https://www.baidu.com/s?wd=你好"
```

- 主缓存：`reference/locators/<site>.elements.json`（机器可读，含全部 xpath / xpathAlt）
- 摘要：`reference/locators/<site>.md`（自动生成）
- 调试报「元素不存在」或缓存超过 7 天 → **新建 Tab 批量重采**（`element-selector.md` §批量采集），或 `update-locators.sh`，再 Read JSON

手动新增指令：复制 [_template.md](reference/commands/_template.md)，并更新 [index.md](reference/commands/index.md)

## 触发判定

- 用户要在 RPA/bots 编排模式工作流中新建指令或调试
- 关键词：rpa.sankuai.com、bots.sankuai.com、编排模式、工作流指令、调试运行、聊天区报错
- **未指定场景/指令**（如仅 `/codex-workflow-command-test` 或泛化「工作流指令测试」）→ **禁止询问**，默认 Read `reference/scenarios/bilibili.md`（B站：打开网页 → 输入文本 → 点击元素 → 刷新网页）
- 「百度场景」→ Read `reference/scenarios/baidu.md`
- **「网页断言测试 / 验证元素 xx / 断言批量」→ Read `reference/scenarios/baidu-assertions.md`**
- **「上传文件指令测试 / UploadFileFromS3 / 图片上传组件 / input[type=file]」→ Read `reference/scenarios/upload-file.md`**
- **「循环遍历元素 / LoopElements / 小红书循环 / outputList / @{toolId.index} / 批量抓取标题」→ Read `reference/scenarios/loop-elements-xhs.md` + `reference/commands/loopelements.md`**
- 「bilibili / B站场景」→ Read `reference/scenarios/bilibili.md`
- 「sogou / 搜狗场景」→ Read `reference/scenarios/sogou.md`（打开网页 → 输入文本 → 点击 → 刷新网页）
- **不适用于**：bots 对话流/知识库、普通网页操作、代码编写

## 边界

- 不负责工作流发布上线，只做指令配置与调试验证
- 元素采集依赖云浏览器连接，断线时需重新连接
- **URL 含 `://` 时禁止 `type_text`**（macOS 会丢冒号 → `https//`）；用 `pbcopy+paste` 或 `set_value`，见 `reference/url-input.md`
- `type_text` 仅适合纯 ASCII 且无 Shift 修饰符的短文本；中文用 pbcopy+paste
- **每次 sky 动作后必须全量抓 AX Tree 验证**，禁止连点不验证（见 `ax-verify.md`）
- 指令语义以官方文档为准；与平台 UI 不一致时以文档为准
- **AntD Select 元素选择器模拟键盘 Cmd+V 不触发 React onChange**（原因：受控组件的 `_valueTracker` 判定值未变）→ 粘贴后**立即按 Enter**，AntD Select 内部的 confirm-input 逻辑会把粘贴文本作为 tag 提交给 React state，红字消失；见 `element-selector.md` §方式 C
- **AntD Select 已有 tag 无法用 Backspace 删除**：改用 click 组合框 → `Cmd+A` → `Cmd+V` 新 XPath → Enter（新 tag 替换旧 tag）；见 `element-selector.md` §失败排查
- **保存关闭后 canvas 节点显示 `selectorId 元素的...`**：XPath 未真正落库，需双击重开弹框方式 C 重填；判定与修复见 `debug.md` §常见环境级异常
- **Chrome `cgWindowNotFound` 或 sky 长 timeout**：Chrome 不是最前台，用 `osascript -e 'tell application "System Events" to set frontmost of application process "Google Chrome" to true'` + `sleep 2` 恢复；见 `debug.md` §常见环境级异常
- **"网页断言"分组中"验证文本存在/不存在"平台指令名不含 `(web)` 后缀**：AX 匹配格式是 `文本 验证文本存在` 而非 `text 验证文本存在 (web)`；见 `commands/index.md` §"网页断言"分组、`scenarios/baidu-assertions.md`
- **"文本输入区（Monaco 类）"字段中文粘贴常失败**：优先 `type_text` + ASCII；必须中文时先 pbcopy → Chrome 强制前台 → Cmd+V；见 `debug.md` §「文本输入区（Monaco 类）」中文粘贴
- **`UploadFileFromS3` 指令**：底层 Playwright `setInputFiles()` 只吃**原生 `<input type=file>`**；S3 路径只支持 **`https://` 前缀**（不支持 `s3://`）；外网站点云浏览器 tunnel 不通（`ant-design.antgroup.com`、`file.io` 等超时）；`data:` URL 被 rpa 前置校验拒。首选**通路 A**：把静态 HTML 上传到 `s3plus.sankuai.com` 让工作流只需 2 节点；详见 `scenarios/upload-file.md`
- **`LoopElements` 指令**：只有 `selector` + `outputList` 是必填；循环体内子指令用 **`@{toolId.index}`**（不是 `${}`）拼接当前 XPath；`outputList` 的 `value` 只能引用循环内部指令的 outKey；循环节点外用 `${outKey.字段名}` 访问收集到的数组。UI「输出参数」表格新加行的 sky idx 极不稳定（AntD Table virtual scroll），**必须同一次 sky exec 内完成「点+ 添加 → 填名称 → 填值」三步**；详见 `commands/loopelements.md` 与 `scenarios/loop-elements-xhs.md`
