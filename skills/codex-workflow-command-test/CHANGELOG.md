# 变更说明

本文件记录每个版本的变更。版本号以 [`skill.json`](skill.json) 中的 `version` 为准。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [Unreleased]

<!-- 下次发版前在此累积变更，发版时移到新版本标题下并清空本节 -->

## [0.0.10] - 2026-08-22

### 新增

- **`reference/sky-runtime.md`**：Sky 运行时共享模块（helper 包、exec 批次策略、Chrome 前台、`defocusCanvas`、插入/LLM/XPath/保存/调试脚本、B 站四步黄金路径、cgWindowNotFound 恢复）

### 变更

- **`SKILL.md`**：配置 vs 调试阶段强制分离；无报错即调试门控；实测经验摘要（B 站四步）；效率与准确率表；reference 索引加入 `sky-runtime.md`
- **`reference/test-workflow.md`**：调试前顺序/配置终检；无报错即调试门控；禁止配置阶段点「调试」
- **`reference/ax-verify.md`**：动作后全量 AX 验证；assertCanSave；插入后顺序校验
- **`reference/debug.md`**：一次性调试、`debugRunOnce`、断开重试、聊天区历史判读
- **`reference/insert-command.md`**：剪切调序、`dblclickWebResultLoose`、刷新网页无 `(web)` 后缀
- **`reference/platform-ops.md`**：canvas 失焦禁止点「调试」；新建工作流 UI 文案「可视化编排」
- **`reference/scenarios/bilibili.md`**：§实测黄金路径（2026-08-22 验证通过）
- **`reference/scenarios/index.md`**：默认场景执行约束与 B 站黄金路径引用（保留 G 场景 web-navigation-basic）
- **`reference/prerequisites.md`** / **`reference/url-input.md`** / **`reference/element-selector.md`**：联动 sky-runtime 与粘贴校验

## [0.0.9] - unreleased

### 变更

- **`reference/insert-command.md`**：新增 §平台 UI 实测踩坑（2026-08）——指令 Tab 前置、搜索框 AX 新模式、`pbcopy+Cmd+V` 禁止 `set_value` 搜指令、双击结果 `(web)` 降级匹配、锚点坐标失败降级路径、拆分 exec 建议、已验证最小插入路径；同步更新第 2/3 步代码样例与 AX 验证表
- **`reference/scenarios/web-navigation-basic.md`**：WF3 网页操作基础场景（百度 / 搜狗 / 新浪真实站点，15 条指令顺序表）
- **`reference/insert-command.md`**：§9 删除节点 **Safari 实测通过**（2026-08-21）：`图像` 索引 `30+(N-2)*2` + `sky.press_key("BackSpace")`；禁止 `Delete`/`Backspace` 键名

- **循环遍历元素专项文档** [`reference/commands/loopelements.md`](reference/commands/loopelements.md)
- **循环遍历·小红书首页场景** [`reference/scenarios/loop-elements-xhs.md`](reference/scenarios/loop-elements-xhs.md)
- **上传文件指令专项场景** [`reference/scenarios/upload-file.md`](reference/scenarios/upload-file.md)
- 场景索引、指令目录、SKILL.md 登记上传/循环遍历触发词

### 变更

- `pnpm run pack` 改为白名单打包，zip 内不再包含开发文件

## [0.0.1] - 2026-07-31

### 新增

- 技能骨架：`SKILL.md` + `reference/` 模块化文档
- 标准测试流程：新建空工作流 → 追加式加指令 → 配表保存 → 调试 → 修复循环
- 内置场景：百度搜索、Bilibili 搜索（`reference/scenarios/`）
- 96 条 UI 指令参数 reference（`reference/commands/`，可 `scrape-commands.py` 同步官方文档）
- 元素 XPath 批量采集与 locators 缓存机制
- 平台操作规范：追加式插入、保存前必填校验、剪切→粘贴调序、URL 输入规范
- 配置校验三条硬规则与调试前后 sky 自动化脚本
- 开发脚本：`pnpm run install`、`pnpm run pack`、`update-locators.sh`、`collect-locators.py`
