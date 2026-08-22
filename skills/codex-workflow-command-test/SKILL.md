---
name: codex-workflow-command-test
description: >
  Bots 平台编排模式工作流指令配置与调试技能。当用户在对话中表达以下意图时激活：
  「在 bots 上新建编排模式工作流」「bots 工作流加指令」「配置 bots 自动化流程」
  「bots 编排模式添加打开网页/导航到URL/输入文本/点击指令」「bots 工作流调试」「bots 调试报错修复」
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
3. 逐条**完善表单并保存**（保存前**必须** `assertCanSave`：`canSave === true` 才允许点「保存」）；每条保存后仅做 **canvas 摘要验证**（节点文案正确即可），**禁止点「调试」**
4. **全部指令保存完成后**点一次「**检查**」→ 无配置异常 badge（中间步骤**跳过**「检查」与「调试」，见 `test-workflow.md`、`sky-runtime.md`）
5. **调试前终检**：场景顺序终检 + 编排区右侧无配置警示 icon
6. **一次性调试** → 弹框**直接运行**（全场景仅 **1 次**「调试 → 运行」，禁止每条指令插入后调试）
7. 执行后检查四处报错来源（聊天区 / 执行 icon / 配置 icon / 「检查」面板）
8. 根据报错修复；修复后**再**一次性调试，禁止边插边调
9. 直到无报错且「检查」无异常

## 配置阶段 vs 调试阶段（强制分离）

> 🚫🚫🚫 **禁止每条指令插入/保存后点「调试」**。调试是**全链路配置完成**后的唯一动作，不是插入过程中的验证手段。

| 阶段 | 允许 | 禁止 |
|------|------|------|
| **配置阶段**（逐条插入 + 配表 + 保存） | canvas 摘要验证、弹框内 assertCanSave、AX 动作-验证循环 | 点「调试」、点「运行」、等云浏览器执行结果 |
| **终检阶段**（全部指令已保存） | 点一次「检查」、顺序终检、配置 icon 终检 | 调试 |
| **调试阶段**（终检全部通过） | **一次性**「调试 → 运行」→ 四处扫描 | 再插入新指令（除非修复失败需删重插） |

插入失败时用 **删除节点 / 重插 / 剪切粘贴** 修复，**不得**用「先调试看看」代替配置验证。

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

## 元素选择器配置（含任意 UI 指令——LLM 默认首选）

> 🚫 **强制规则**：任务含元素选择器的**任意** UI 指令（含 FillText、点击、断言类、等待类等所有需「元素选择器」字段的指令），默认先走 **新建 LLM / LLM动态定位**，失败或运行报错后再降级 XPath。

1. Read `scenarios/<场景>.md` → 列出全部待定位元素，并为每个元素准备自然语言描述（元素位置 + 操作意图）
2. 按 **`element-selector.md` §方式 A：LLM 动态定位 / 新建 LLM（默认首选）**：点击「新建 LLM」→ 在「LLM动态定位」输入自然语言描述 → **先点「确认」** → 验证描述 + `LLM` 已落库
3. 补齐其它必填项并保存；若 LLM 定位保存后仍显示 `selectorId`、或调试报元素不存在，再按 `element-selector.md` §批量采集（新建 Tab）采 XPath 并降级处理

**元素选择器写入策略优先级**：**方式 A（新建 LLM / LLM动态定位，默认）** → **方式 C（XPath：pbcopy + Cmd+V + Enter）** → **方式 B（平台捕获）**。使用 LLM 时必须点击「确认」后再保存；使用 XPath 时必须在 Cmd+V 后立即按 Enter；禁止其他手工写入方式（如点击「以…为定位器」下拉、DevTools React setter、type_text、set_value 直写、CSS 属性定义）。

> ⚠️ **禁止**在工作流 Tab 地址栏导航探测；XPath 仅作为 LLM 失败/运行报错后的降级方案。

## 用户意图最高优先级（必读 · 先于默认场景）

> 用户消息中**明确指定的指令名**，优先级**高于**场景文件默认值与示例脚本硬编码。

**执行第一步**：Read **[reference/user-intent.md](reference/user-intent.md)** → 解析 `instructionPlan`（搜索名、reference、URL 字段）→ **再** Read 场景/locators/insert-command。

| 用户说了 | 必须做 | 禁止做 |
|---------|--------|--------|
| 「导航到url / 导航到URL」 | 搜索框输入 **`导航到URL`**；Read `navigatetourl.md`；填 `导航到的网址` | ❌ 搜「打开网页」 |
| 「打开网页」 | 搜索 **`打开网页`**；Read `openurl.md` | ❌ 换成导航到URL |
| 显式列出 N 条指令 | **只插这 N 条** | ❌ 擅自加场景默认的「刷新网页」等 |
| 仅「搜狗/sogou 场景」未列指令 | 用 `scenarios/sogou.md` **默认四步** | — |

示例：`以 sogou.com 测试导航到url、输入文本、点击元素` → 3 步：**导航到URL → 输入文本 → 点击**（不含刷新）。详见 `user-intent.md` §示例 A。

## 默认场景（无用户输入时）

用户仅激活本技能、**未指定测试场景或测试指令**时：

- **禁止**向用户询问场景、指令列表或工作流名称
- **直接** Read `reference/scenarios/bilibili.md` 并按默认四步执行：**打开网页 → 输入文本 → 点击元素 → 刷新网页**
- 工作流名称可用 `Bilibili搜索测试-YYYYMMDD`；仅当用户显式给出名称时才改用用户名称
- 验证依赖就绪后**立即**进入 platform-ops / test-workflow，不要等待用户确认

## 执行效率与准确率（强制）

> 完整 helper、批次策略、等待表见 **`reference/sky-runtime.md`**（每次 sky 自动化前 Read）。

| 原则 | 要求 | 禁止 |
|------|------|------|
| **Chrome 前台** | 每个 exec **批次**前 Shell 激活 Chrome；`-10005 cgWindowNotFound` → 按 `sky-runtime.md` 恢复 | 未恢复时连发 exec |
| **Exec 批次** | 一条指令 = 一次 exec；4 步场景 ≤ 6 次 exec | 每条指令拆 5+ exec；配置未完成就运行 |
| **禁止盲 sleep** | 搜索框用 `waitSearchIdx()` 轮询 | 固定 2s 盲等 |
| **剪贴板** | URL/XPath/中文：**Shell** `pbcopy` | nodeRepl 内 `execFileSync('pbcopy')` |
| **钉住工作流 Tab** | XPath 采集仅 **Cmd+T 新 Tab** | 工作流 Tab 地址栏打开目标站 |
| **LLM 确认** | 只用 `LLM动态定位` slice 内「确 认」 | 全局第一个确认按钮 |
| **ASCII 待填充** | `bilibili` 等纯 ASCII 用 `type_text` | 对 ASCII 用 paste |
| **禁止点「调试」** | 配置阶段不点「调试」；失焦用「编排区」Tab + Escape | 用「调试」失焦；每条指令后调试 |
| **锚点关键词** | canvas 摘要作锚点（`bilibili.com`、`元素中输入 bilibili`） | 泛搜 `点击`/`输入` |
| **顺序错乱** | `Cmd+X` → 锚点 Enter → `Cmd+V` | 带错顺序继续配表/调试 |
| **刷新网页插入** | `dblclickWebResultLoose("刷新网页")` | 死等 `(web)` 正则 |
| **canvas 验证** | 每条保存后读摘要行；失败 2 次删节点或新建工作流 | 堆脏节点 |
| **新建工作流 UI** | 平台为「**可视化编排**」 | 旧文案「编排模式」 |

## 实测经验摘要（B 站四步 · 2026-08-22 验证通过）

> 完整锚点、LLM 文案、exec 批次见 **`reference/scenarios/bilibili.md` §实测黄金路径** 与 **`reference/sky-runtime.md` §B 站四步黄金路径**。

| 要点 | 实测结论 |
|------|---------|
| 配置 vs 调试 | 4 条指令全部保存 + canvas 验证 → **只点 1 次**「检查」→ **只点 1 次**「调试 → 运行」 |
| canvas 失焦 | **编排区 Tab + Escape**；曾误用「调试」按钮失焦 → 用户看到反复点调试、聊天区堆失败日志 |
| 插入锚点 | 每条向后追加必须选中**上一条已保存指令**再 Enter；锚点用摘要行关键词，插入后立刻核对顺序 |
| 点击未落库 | canvas 显示 `selectorId` → **双击该节点**开弹框 → `configLLMScoped` → 保存；摘要变为 `点击 页面` 即 OK |
| 刷新网页 | 右侧面板结果为 `文本 刷新网页`（网页自动化分组下），**不必**匹配 `(web)` |
| 调试按钮灰 | 若「调试」「运行」disabled 且 AX 含「调试中」→ **等执行结束**或先点「断开」再重试 |
| 聊天区历史 | 早先误触调试的失败日志会残留；以**最新一轮** `check-circle` 时间戳为准判 PASS |

## 执行流程

```
0. reference/user-intent.md          ← 解析用户显式指令（最高优先级）；有则覆盖场景默认指令名
1. reference/prerequisites.md       ← cua-router-basic 安装验证
2. reference/sky-runtime.md         ← 共享 helper、exec 批次、Chrome 前台、等待表（sky 自动化必读）
3. reference/ax-verify.md         ← 动作后全量 AX 验证；AX → OCR → 坐标扫描三级定位（sky 操作必遵）
4. reference/test-workflow.md       ← 测试标准流程（新建→加指令→调试→修复）
5. reference/scenarios/<场景>.md    ← 站点 URL、XPath；指令链以 user-intent 为准
6. reference/element-selector.md  ← 需元素选择器时：默认新建 LLM / LLM动态定位；失败后降级 XPath 批量采集
7. reference/locators/<site>.*      ← XPath 降级缓存（可选，仅 LLM 失败/运行报错后优先 Read）
8. reference/commands/<指令>.md     ← 单条指令参数（来自 instructionPlan）
9. reference/url-input.md           ← 填 URL 字段时必读（网址 / 导航到的网址）
10. reference/debug.md               ← 报错修复与重插策略
```

> ⚠️ **硬性前置**：未完成 `prerequisites.md` 且验证输出 `ok` 前，**不得**调用 `sky.*` 或操作 bots 平台。

## Reference 模块索引

Reference 文件位于本技能目录下的 `reference/`，与 `SKILL.md` 同级。执行时用 Read 工具读取对应路径。

| 模块 | 文件 | 何时 Read |
|------|------|----------|
| **用户意图解析** | [reference/user-intent.md](reference/user-intent.md) | **每次执行最先**（用户消息含显式指令名时必读） |
| 前置依赖 | [reference/prerequisites.md](reference/prerequisites.md) | **每次执行**（cua-router 验证） |
| **Sky 运行时** | [reference/sky-runtime.md](reference/sky-runtime.md) | **每次 sky 自动化必读**（helper、批次、前台、等待表） |
| **AX 步骤验证** | [reference/ax-verify.md](reference/ax-verify.md) | **每次 sky 操作必遵** |
| **测试标准流程** | [reference/test-workflow.md](reference/test-workflow.md) | **每次测试必读** |
| 平台操作 | [reference/platform-ops.md](reference/platform-ops.md) | 新建工作流、canvas 双击、保存前校验 |
| 指令目录（98 条 UI 指令） | [reference/commands/index.md](reference/commands/index.md) | 查找/确认任意 UI 指令参数 |
| 单条指令 | `reference/commands/<slug>.md` | 配置具体指令节点时按需 Read |
| **捕获元素** | [reference/capture-element.md](reference/capture-element.md) | **需通过平台「捕获」按钮采集元素时**：6 步捕获流程、多信号判据 |
| 元素选择器 | [reference/element-selector.md](reference/element-selector.md) | **默认首选**新建 LLM / LLM动态定位（填自然语言描述 → 点「确认」→ 保存）；LLM 失败或运行报错后才降级 XPath（方式 C），再失败转捕获（方式 B） |
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
- 「sogou / 搜狗场景」→ Read `reference/scenarios/sogou.md`；**若用户同时指定指令名**（如「导航到url」）→ **`user-intent.md` 优先**，不得用场景默认「打开网页」替代
- **不适用于**：bots 对话流/知识库、普通网页操作、代码编写

## 边界

- 不负责工作流发布上线，只做指令配置与调试验证
- 元素采集依赖云浏览器连接，断线时需重新连接
- **URL 含 `://` 时禁止 `type_text`**；弹框填 URL **默认 scoped + 剪贴板 + paste**（`url-input.md` §执行顺序铁律）；**禁止** pbcopy 失败就改 set_value
- **点「保存」前必须 assertCanSave**：任一 label 前带 `*` 的字段仍空、仍占位符、仍红框、或 AX 有「该字段是必填字段」→ `canSave === false`，**禁止 click 保存**（见 `platform-ops.md` §2.4、`ax-verify.md` §assertCanSave）
- **用户显式指令名优先于场景默认**：说「导航到url」必须搜 `导航到URL`，禁止偷换「打开网页」（见 `user-intent.md`）
- **配置 URL 弹框字段时禁止误填 Chrome 地址栏**（`网址` / `导航到的网址`）：见 `reference/url-input.md` §弹框网址 vs Chrome 地址栏
- `type_text` 仅适合纯 ASCII 且无 Shift 修饰符的短文本；中文用 pbcopy+paste
- **每次 sky 动作后必须全量抓 AX Tree 验证**，禁止连点不验证（见 `ax-verify.md`）
- 指令语义以官方文档为准；与平台 UI 不一致时以文档为准
- **AntD Select 元素选择器模拟键盘 Cmd+V 不触发 React onChange**（原因：受控组件的 `_valueTracker` 判定值未变）→ 粘贴后**立即按 Enter**，AntD Select 内部的 confirm-input 逻辑会把粘贴文本作为 tag 提交给 React state，红字消失；见 `element-selector.md` §方式 C
- **AntD Select 已有 tag 无法用 Backspace 删除**：改用 click 组合框 → `Cmd+A` → `Cmd+V` 新 XPath → Enter（新 tag 替换旧 tag）；见 `element-selector.md` §失败排查
- **保存关闭后 canvas 节点显示 `selectorId 元素的...`**：XPath 未真正落库，需双击重开弹框方式 C 重填；判定与修复见 `debug.md` §常见环境级异常
- **Chrome `cgWindowNotFound` 或 sky 长 timeout**：按 **`sky-runtime.md` §cgWindowNotFound 恢复顺序**；见 `debug.md` §常见环境级异常
- **"网页断言"分组中"验证文本存在/不存在"平台指令名不含 `(web)` 后缀**：AX 匹配格式是 `文本 验证文本存在` 而非 `text 验证文本存在 (web)`；见 `commands/index.md` §"网页断言"分组、`scenarios/baidu-assertions.md`
- **"文本输入区（Monaco 类）"字段中文粘贴常失败**：优先 `type_text` + ASCII；必须中文时先 pbcopy → Chrome 强制前台 → Cmd+V；见 `debug.md` §「文本输入区（Monaco 类）」中文粘贴
- **`UploadFileFromS3` 指令**：底层 Playwright `setInputFiles()` 只吃**原生 `<input type=file>`**；S3 路径只支持 **`https://` 前缀**（不支持 `s3://`）；外网站点云浏览器 tunnel 不通（`ant-design.antgroup.com`、`file.io` 等超时）；`data:` URL 被 rpa 前置校验拒。首选**通路 A**：把静态 HTML 上传到 `s3plus.sankuai.com` 让工作流只需 2 节点；详见 `scenarios/upload-file.md`
- **`LoopElements` 指令**：只有 `selector` + `outputList` 是必填；循环体内子指令用 **`@{toolId.index}`**（不是 `${}`）拼接当前 XPath；`outputList` 的 `value` 只能引用循环内部指令的 outKey；循环节点外用 `${outKey.字段名}` 访问收集到的数组。UI「输出参数」表格新加行的 sky idx 极不稳定（AntD Table virtual scroll），**必须同一次 sky exec 内完成「点+ 添加 → 填名称 → 填值」三步**；详见 `commands/loopelements.md` 与 `scenarios/loop-elements-xhs.md`
