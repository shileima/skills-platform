# RPA 工作流指令测试

在 **rpa.sankuai.com / bots.sankuai.com** 编排模式工作流中，按场景添加 Web 自动化指令、配置表单、调试运行并修复报错，直到全部通过。

| 项 | 值 |
|---|---|
| 技能 ID（目录名） | `codex-workflow-command-test` |
| automan 注册名 | `rpa-workflow-instruction-test`（见 `skill.json` → `automan.metaName`） |
| 当前版本 | 见 `skill.json` → `version` |
| 作者 | mashilei |
| 依赖 | [cua-router-basic](https://github.com/shileima/cua-router-basic) |

> 本技能由 [`skills-platform`](../../README.md) 仓库统一管理与发布。**元数据权威来源是 `skill.json`**；各生态的产物（如 automan 的 `.meta.json`、分发 zip）都由 `skilldev` 自动生成，请勿手写。

## 适用场景

- 新建空编排工作流，按序插入「打开网页 / 输入文本 / 点击」等指令
- 配置元素选择器、URL、Cookie 等参数并调试
- 内置测试场景：**百度搜索**、**Bilibili 搜索**
- Agent 执行入口：Read 本目录 `SKILL.md`（触发词与完整流程见 frontmatter）

## 目录结构

```
codex-workflow-command-test/
├── SKILL.md                 # Agent 主入口（frontmatter + 流程索引）
├── skill.json               # 技能元数据（名称、版本、targets、依赖、打包白名单）— 权威来源
├── CHANGELOG.md             # 版本变更说明
├── reference/               # 分模块文档（按需 Read，勿全量加载）
│   ├── test-workflow.md     # 标准测试流程
│   ├── platform-ops.md      # 平台操作与保存前校验
│   ├── debug.md             # 调试与修复
│   ├── commands/            # 96 条 UI 指令参数
│   └── scenarios/           # 百度 / B站 场景
└── scripts/
    ├── scrape-commands.py   # 从官方文档同步指令 reference
    ├── update-locators.sh   # 更新元素 XPath 缓存
    └── collect-locators.py  # 采集页面元素
```

> `.meta.json` 与 `dist/` 不在源目录中：前者在打包/安装 automan 时由 `skilldev` 从 `skill.json` 生成，后者是 `skilldev` 的构建输出（仓库根 `dist/`，已 gitignore）。

## 元数据约定

| 位置 | 用途 |
|------|------|
| **`skill.json`** | 权威元数据：`name` / `version` / `targets` / `dependencies` / `pack.include` / `automan.metaName` |
| **`SKILL.md` frontmatter** | 仅 `name` / `description`（Agent 触发与执行说明），`name` 必须与目录名一致 |
| **`.meta.json`（生成物）** | automan 平台 UI / 版本 / 依赖；由 `skilldev` 从 `skill.json` 派生，勿手改 |

automan 注册名与目录名不同（`rpa-workflow-instruction-test` vs `codex-workflow-command-test`），通过 `skill.json` 的 `automan.metaName` 保留，避免破坏既有 automan 注册。

## 安装

在 `skills-platform` 仓库根执行（生态目录默认 `~/.<eco>/skills/<name>/`）：

```bash
# 先干跑确认目标路径，不写盘
skilldev install codex-workflow-command-test --target automan --dry-run

# 正式安装到某个生态（claude | codex | cursor | automan | all）
skilldev install codex-workflow-command-test --target automan

# 安装并一并装依赖（cua-router-basic，会执行其 install 脚本）
skilldev install codex-workflow-command-test --target automan --install-deps
```

依赖来自 `skill.json` → `dependencies`。默认**不**自动执行依赖安装脚本（`curl | bash` 属外部动作）；需要时显式加 `--install-deps`，或手动执行下方命令并校验 `sky.*` 就绪：

```bash
curl -fsSL https://raw.githubusercontent.com/shileima/cua-router-basic/main/scripts/install-remote.sh | bash
```

## 打包分发（automan zip）

```bash
skilldev pack codex-workflow-command-test
```

按 `skill.json` → `pack.include` 白名单（`.meta.json`、`SKILL.md`、`README.md`、`CHANGELOG.md`、`reference`、`scripts`）打包，产物用 **automan 注册名 + 版本** 命名：

```
dist/rpa-workflow-instruction-test_0.0.1.zip
```

`.meta.json` 会在打包时自动生成并置于包内根层。

## 版本发布流程

1. 完成代码 / 文档改动
2. 升版本：`skilldev version codex-workflow-command-test patch`（或 `minor` / `major` / 指定 `x.y.z`）——会更新 `skill.json` 并向 `CHANGELOG.md` 追加条目骨架
3. 在 `CHANGELOG.md` 填写本次变更
4. 校验：`skilldev validate codex-workflow-command-test`
5. 打包：`skilldev pack codex-workflow-command-test`
6. 提交 git 并打 tag（可选）：`v0.0.2`

## 快速链接

- 指令官方文档：<https://document.waimai.st.sankuai.com/>
- 标准测试流程：[reference/test-workflow.md](reference/test-workflow.md)
- 配置校验三条硬规则：[SKILL.md](SKILL.md#配置校验三条硬规则)

## 变更历史

见 [CHANGELOG.md](CHANGELOG.md)。
