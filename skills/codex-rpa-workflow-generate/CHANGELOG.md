# Changelog — codex-rpa-workflow-generate

## [0.1.1] - unreleased

### Fixed

- WaitPageState：`timeout` 移入 `waitForLoadStateOptions`，修复引擎报错
- SendKeys：字段名改为 `keys`；NavigateToUrl 改为 `rawUrl`
- TakeScreenshot：补全 `screenshotOption`；Delay 改为 `second` + `timeUnit`

### Added

- `scripts/validate-built-nodes.mjs` 构建后校验已知 formData 陷阱
- `reference/form-data-rules.md` 经调试沉淀的字段规范
- `generate-workflow.sh` 生成前自动校验

## [0.1.0] - unreleased

### Added

- 根据 instruction-plan.json 调用 digitalgateway API 构建 rpaNode JSON
- 剪贴板协议批量粘贴到空编排工作流
- Automan 本地 xcAuth 鉴权
- 不入库 LLM 元素选择器构建
- 内置 B 站/携程/比价/搜狗场景模板
- 自动调用 codex-rpa-workflow-create 创建空工作流
- 生成后交接 codex-workflow-command-test 调试
