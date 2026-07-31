# 变更说明

本文件记录每个版本的变更。版本号以 [`.meta.json`](.meta.json) 中的 `version` 为准。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [Unreleased]

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

[Unreleased]: https://github.com/shileima/rpa-workflow-command-test/compare/v0.0.1...HEAD
[0.0.1]: https://github.com/shileima/rpa-workflow-command-test/releases/tag/v0.0.1
