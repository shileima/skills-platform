# RPA 工作流指令测试

在 **rpa.sankuai.com / bots.sankuai.com** 编排模式工作流中，按场景添加 Web 自动化指令、配置表单、调试运行并修复报错，直到全部通过。

| 项 | 值 |
|---|---|
| 技能 ID | `rpa-workflow-command-test` |
| 展示名称 | 见 `.meta.json` → `name` |
| 当前版本 | 见 `.meta.json` → `version` |
| 作者 | mashilei |
| 依赖 | [cua-router-basic](https://github.com/shileima/cua-router-basic) |

## 适用场景

- 新建空编排工作流，按序插入「打开网页 / 输入文本 / 点击」等指令
- 配置元素选择器、URL、Cookie 等参数并调试
- 内置测试场景：**百度搜索**、**Bilibili 搜索**
- Agent 执行入口：Read 本目录 `SKILL.md`（触发词与完整流程见 frontmatter）

## 目录结构

```
rpa-workflow-command-test/
├── SKILL.md                 # Agent 主入口（frontmatter + 流程索引）
├── .meta.json               # 技能元数据（名称、版本、依赖）— 权威来源
├── CHANGELOG.md             # 版本变更说明
├── package.json             # 仅 dev scripts（install / pack，不打进 zip）
├── reference/               # 分模块文档（按需 Read，勿全量加载）
│   ├── test-workflow.md     # 标准测试流程
│   ├── platform-ops.md      # 平台操作与保存前校验
│   ├── debug.md             # 调试与修复
│   ├── commands/            # 96 条 UI 指令参数
│   └── scenarios/           # 百度 / B站 场景
├── scripts/
│   ├── install.js           # 安装 .meta.json 声明的依赖（dev，不打进 zip）
│   ├── pack.js              # 打包 zip（dev，不打进 zip）
│   ├── scrape-commands.py   # 从官方文档同步指令 reference
│   └── update-locators.sh   # 更新元素 XPath 缓存
└── dist/                    # 打包输出（git 可不提交）
```

### 分发包内容（`pnpm run pack` 白名单）

zip 内**仅含**技能运行所需文件：

| 路径 | 说明 |
|------|------|
| `.meta.json` | 平台元数据、依赖声明 |
| `SKILL.md` | Agent 主入口 |
| `README.md` / `CHANGELOG.md` | 说明与版本记录 |
| `reference/` | 全部 reference 文档 |
| `scripts/scrape-commands.py` | 同步官方指令文档 |
| `scripts/update-locators.sh` | 更新 XPath 缓存 |
| `scripts/collect-locators.py` | 采集页面元素 |

**不包含**（仅开发/发版用）：`package.json`、`pnpm-lock.yaml`、`scripts/install.js`、`scripts/pack.js`、`dist/`、`.git/`

## 元数据约定

| 文件 | 用途 |
|------|------|
| **`.meta.json`** | 平台 UI、版本号、依赖声明、打包文件名 |
| **`SKILL.md` frontmatter** | Agent 触发与执行说明 |
| **`package.json`** | 仅 `pnpm run install` / `pnpm run pack`，**不**重复写技能元数据，**不打进 zip**

发版或改版本时：**只改 `.meta.json` 的 `version`**，并在 `CHANGELOG.md` 追加对应条目。

## 安装

### 1. 放置技能目录

```bash
# 全局（推荐）
~/.automan/skills/rpa-workflow-command-test/

# 或 Cursor
~/.cursor/skills/rpa-workflow-command-test/
```

### 2. 安装依赖

```bash
cd ~/.automan/skills/rpa-workflow-command-test
pnpm run install
```

会读取 `.meta.json` → `dependencies`，安装 `cua-router-basic` 并校验 `sky.*` 就绪。

## 打包分发

```bash
pnpm run pack
```

根据 `.meta.json` 的 `name` 与 `version` 生成（**仅含技能运行文件**，见上文「分发包内容」）：

```
dist/{name}_{version}.zip
```

示例：`dist/RPA工作流指令测试_0.0.1.zip`（以 `.meta.json` 实际字段为准）

## 版本发布流程

1. 完成代码 / 文档改动
2. 更新 `.meta.json` → `version`（语义化版本 `x.y.z`）
3. 在 `CHANGELOG.md` 的 `[Unreleased]` 下写变更，发布时移到新版本标题下
4. 执行 `pnpm run pack` 生成 zip
5. 提交 git 并打 tag（可选）：`v0.0.2`

## 快速链接

- 指令官方文档：<https://document.waimai.st.sankuai.com/>
- 标准测试流程：[reference/test-workflow.md](reference/test-workflow.md)
- 配置校验三条硬规则：[SKILL.md](SKILL.md#配置校验三条硬规则)

## 变更历史

见 [CHANGELOG.md](CHANGELOG.md)。
