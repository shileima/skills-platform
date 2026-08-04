# AGENTS.md — 给在本仓库工作的 coding agent

`skills-platform` 是一个**技能开发/发布仓库**。技能源只维护一份，投递到多生态。

## 硬规则

1. **唯一事实来源是 `skills/<name>/`。** 不要手改 `dist/`、也不要直接编辑各生态目录（`~/.claude/skills` 等）里的文件 —— 改源，再 `skilldev install`。
2. **`SKILL.md` frontmatter 只放 `name` 和 `description`。** 其它元数据放 `skill.json`。两者的 `name` 必须与目录名一致。
3. **automan 的 `.meta.json` 是生成物，不手写。** 由 `skill.json` 派生（automan 名称如需与目录名不同，用 `skill.json.automan.metaName`）。
4. **改完必须 `skilldev validate` 通过**再提交。
5. **安装到生态目录前先 `--dry-run`**，确认不会覆盖别人的技能。

## 常用流程

```bash
node bin/skilldev.mjs new <name>          # 新技能
node bin/skilldev.mjs validate            # 校验全部
node bin/skilldev.mjs build <name> --target all
node bin/skilldev.mjs install <name> --target claude --dry-run
node bin/skilldev.mjs pack <name>         # automan zip
node bin/skilldev.mjs version <name> patch
```

## 代码结构

- `bin/skilldev.mjs` → `src/cli.mjs`（命令分发）→ `src/commands/*.mjs`
- `src/adapters/*.mjs`：每生态一个，统一接口 `id / skillsDir() / stage() / postInstall()`
- `src/lib/*.mjs`：`frontmatter`、`skill`、`ecosystems`（路径集中处）、`fsutil`、`semver`、`zip`、`log`、`modules`
- `src/modules/<name>/`：技能共享模块（build/install 时拷贝到 `<skill>/modules/<name>/`）
- 测试：`tests/*.test.mjs`（`node --test`）

修改工具行为时，优先改 `src/lib` 与 `src/adapters`，命令层保持薄。
