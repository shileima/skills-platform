# 变更说明


## [0.0.9] - unreleased

### Changed
-

本文件记录每个版本的变更。版本号以 [`.meta.json`](.meta.json) 中的 `version` 为准。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [Unreleased]

### 新增

- **循环遍历元素专项文档** [`reference/commands/loopelements.md`](reference/commands/loopelements.md)：`LoopElements` 完整参数表（13 个），官方 XML DSL 示例（含 `outputList`、`@{toolId.index}`、`outKey`），3 类循环体子指令组合（单字段收集 / 多字段收集 / 滚动加载），配置要点，sky 自动化配置示例（关键：**同一次 sky exec 内完成"点+添加 → 填名称 → 填值"**，跨 exec idx 失效），常见踩坑对照表
- **循环遍历·小红书首页场景** [`reference/scenarios/loop-elements-xhs.md`](reference/scenarios/loop-elements-xhs.md)：
  - 目标：用 LoopElements 遍历 `xiaohongshu.com/explore` 首屏 32 条 `<a class="title">` 笔记标题
  - 4 节点工作流：打开网页 → 循环遍历元素（含 GetText 子指令）→ 打印日志（循环外用 `${loopResult.titles}` 输出数组）
  - 完整 XML DSL、5 步执行清单、预期结果、场景专属踩坑（GetText 未用 `@{loopResult.index}` → 拿到重复元素 / 子指令未嵌入循环内 / 表格 idx 失效等）
- **上传文件指令专项场景** [`reference/scenarios/upload-file.md`](reference/scenarios/upload-file.md)：`UploadFileFromS3` 端到端测试（云浏览器网络限制清单、s3plus 静态 HTML 通路、rpa 自身「新建工作流→自定义上传」5 节点通路、失败 URL/XPath 表）
- 场景索引 [`scenarios/index.md`](reference/scenarios/index.md) 加入场景 D 与场景 E 入口
- 指令目录 [`commands/index.md`](reference/commands/index.md) 加入「循环遍历元素」行
- 指令 [`commands/uploadfilefroms3.md`](reference/commands/uploadfilefroms3.md) 追加「适用性预判清单」「推荐通路」「已知失败案例」三节
- SKILL.md description 与 reference 索引登记「上传文件」「循环遍历元素」两条触发关键词与场景文件；边界条款各补 1 条铁律

### 变更

- `pnpm run pack` 改为白名单打包，zip 内不再包含 `package.json`、`pnpm-lock.yaml`、`scripts/install.js`、`scripts/pack.js` 等开发文件

<!-- 下次发版前在此累积变更，发版时移到新版本标题下并清空本节 -->

## [0.0.1] - 2026-07-31

### 新增

- 技能骨架：`SKILL.md` + `reference/` 模块化文档
- 标准测试流程：新建空工作流 → 追加式加指令 → 配表保存 → 调试 → 修复循环
- 内置场景：百度搜索、Bilibili 搜索（`reference/scenarios/`）
- 96 条 UI 指令参数 reference（`reference/commands/`，可 `scrape-commands.py` 同步官方文档）
- 元素 XPath 批量采集与 locators 缓存机制
- 平台操作规范：追加式插入、保存前必填校验、剪切→粘贴调序、URL 输入规范
- **配置校验三条硬规则**：
  1. 每条保存后点「检查」读下拉面板
  2. 调试前扫描编排区**右侧**配置警示（非仅左侧执行 icon）
  3. 保存前按 `commands/<slug>.md` 核对条件必填（如 SetCookie Domain）
- 调试前后 sky 自动化脚本（`config-check-panel`、`pre-debug-config-check`、`post-debug-four-way-check` 等）
- 开发脚本：
  - `pnpm run install` — 从 `.meta.json` 安装依赖并校验 cua-router-basic
  - `pnpm run pack` — 打包 `dist/{name}_{version}.zip`（白名单，仅技能运行文件）
- `.meta.json` 作为技能元数据权威来源；`package.json` 仅保留 dev scripts

### 依赖

- `cua-router-basic`（sky.* API 操作 Chrome）

[Unreleased]: https://github.com/shileima/codex-workflow-command-test/compare/v0.0.1...HEAD
[0.0.1]: https://github.com/shileima/codex-workflow-command-test/releases/tag/v0.0.1
