# skills-platform

在一个仓库里**开发多个 agent 技能**，做**版本控制**与**测试**，并**一键安装/发布到 `.claude`、`.codex`、`.automan`、`.cursor` 等生态**。

灵感来自 [obra/superpowers](https://github.com/obra/superpowers)：技能源只维护一份（canonical `skills/`），由 `skilldev` CLI 转换并投递到各生态目录。

## 快速开始

```bash
cd skills-platform
npm install                      # 安装 js-yaml（唯一运行时依赖）

node bin/skilldev.mjs list       # 列出所有技能
node bin/skilldev.mjs validate   # 校验全部技能
node bin/skilldev.mjs doctor     # 检查各生态目录 / node / zip
```

安装 `skilldev` 到 PATH（可选）：`npm link`，之后可直接 `skilldev <command>`。

## 一个技能长什么样

```
skills/<name>/
├── SKILL.md        # 必需。YAML frontmatter 仅 name / description（各生态通用）
├── skill.json      # 必需。元数据超集（version / author / targets / dependencies / pack …）
├── README.md       # 可选，人读文档
├── CHANGELOG.md    # 可选，本技能变更日志
├── reference/      # 可选，渐进式披露文档（按需 Read）
├── scripts/        # 可选，运行时脚本
├── assets/         # 可选
└── tests/          # 可选，行为测试场景
```

`SKILL.md` 与 `skill.json` 的 `name` 必须一致（`validate` 会校验）。automan 的 `.meta.json` 由 `skill.json` 自动生成，无需手写。

### skill.json 字段

```json
{
  "name": "my-skill",
  "version": "0.0.1",
  "description": "一句话说明技能做什么、何时激活",
  "author": "you",
  "license": "MIT",
  "keywords": ["..."],
  "targets": ["claude", "codex", "automan", "cursor"],
  "dependencies": [
    { "name": "cua-router-basic", "install": "curl -fsSL https://.../install-remote.sh | bash" }
  ],
  "pack": { "include": [".meta.json", "SKILL.md", "README.md", "CHANGELOG.md", "reference", "scripts"] },
  "automan": { "source": "user", "metaName": "可选：覆盖 .meta.json 的 name" }
}
```

## CLI 命令

| 命令 | 说明 |
| --- | --- |
| `skilldev new <name>` | 用模板脚手架一个新技能 |
| `skilldev list` | 列出技能：名称 / 版本 / targets |
| `skilldev validate [skill]` | 校验 frontmatter、name 一致性、semver、targets、相对链接；失败非零退出 |
| `skilldev build [skill] [--target …]` | 转换到 `dist/<target>/<name>/`；automan 额外生成 `.meta.json` |
| `skilldev install <skill> [--target claude\|codex\|automan\|cursor\|all] [--link] [--dry-run]` | 安装进 `~/.<eco>/skills/<name>/` |
| `skilldev pack <skill>` | 按白名单产出 `dist/<name>_<version>.zip`（automan 分发件） |
| `skilldev version <skill> <newver\|major\|minor\|patch>` | 升版 `skill.json` + 追加 CHANGELOG 骨架 |
| `skilldev manifest` | 在仓库根生成整仓插件清单（marketplace 分发，次要能力） |
| `skilldev doctor` | 环境自检 |

`--dry-run` 只打印将写入的路径，不落盘 —— 安装前先用它确认目标，避免覆盖既有技能。

## 生态目录（可用环境变量覆盖）

| 生态 | 默认安装路径 | 覆盖变量 |
| --- | --- | --- |
| claude | `~/.claude/skills` | `SKILLDEV_CLAUDE_SKILLS_DIR` |
| codex | `~/.codex/skills` | `SKILLDEV_CODEX_SKILLS_DIR` |
| cursor | `~/.cursor/skills` | `SKILLDEV_CURSOR_SKILLS_DIR` |
| automan | `~/.automan/skills` | `SKILLDEV_AUTOMAN_SKILLS_DIR` |

`claude/codex/cursor` 只需拷贝 `SKILL.md` + 支撑目录；`automan` 额外生成 `.meta.json` 并支持 zip 打包与依赖安装。

## 新增一个生态

见 [docs/porting-to-a-new-ecosystem.md](docs/porting-to-a-new-ecosystem.md)：加一个 `src/adapters/<eco>.mjs` 并在 `src/lib/ecosystems.mjs` 注册即可。

## 开发

```bash
npm test              # node --test tests/
bash scripts/ci.sh    # validate 全部技能 + 单测
```
