# 前置依赖：cua-router-basic

本技能所有浏览器自动化均通过 `cua-router-basic` 提供的 `sky.*` API 完成。**不得跳过此模块直接操作 Chrome。**

## 检查是否已就绪

`SKILL_ROOT` 默认路径：若存在 `~/.automan/skills` 则为 `~/.automan/skills/cua-router-basic`，否则为 `~/.cursor/skills/cua-router-basic`（可通过 `CUA_ROUTER_INSTALL_DIR` 覆盖）。

```bash
SKILL_ROOT="${CUA_ROUTER_INSTALL_DIR:-${HOME}/.automan/skills/cua-router-basic}"
if [ ! -f "$SKILL_ROOT/SKILL.md" ]; then
  SKILL_ROOT="${HOME}/.cursor/skills/cua-router-basic"
fi

# 以下任一不满足即视为未就绪，必须安装
test -f "$SKILL_ROOT/SKILL.md" && test -x "$SKILL_ROOT/vendor/codex/bin/codex"
echo "SKILL_ROOT=$SKILL_ROOT"
```

**未就绪判定**（满足任一即需安装）：
- `$SKILL_ROOT/SKILL.md` 不存在
- `$SKILL_ROOT/vendor/codex/bin/codex` 不可执行

## 未安装时：远程一键安装

```bash
curl -fsSL https://raw.githubusercontent.com/shileima/cua-router-basic/main/scripts/install-remote.sh | bash
```

> 若技能目录已存在但仅缺 vendor，可改用：
> `bash "$SKILL_ROOT/scripts/install-full.sh" --vendor-mode auto`

## 安装后验证

```bash
SKILL_ROOT="${CUA_ROUTER_INSTALL_DIR:-${HOME}/.automan/skills/cua-router-basic}"
if [ ! -f "$SKILL_ROOT/SKILL.md" ]; then
  SKILL_ROOT="${HOME}/.cursor/skills/cua-router-basic"
fi
bash "$SKILL_ROOT/scripts/daemon.sh" start
bash "$SKILL_ROOT/scripts/exec.sh" 'nodeRepl.write("ok")'
# 输出 ok 表示 cua-router-basic 已就绪
```

验证失败时：**停止后续步骤**，排查安装日志并重试；**不得**在未就绪状态下调用 `sky.*`。

## 就绪后

1. 读取 `$SKILL_ROOT/SKILL.md`，按其中的 Bootstrap 与操作规范初始化 sky runtime
2. 确认 cua-router 服务已运行（`daemon.sh start`）
3. 阅读 **`reference/ax-verify.md`**（动作-验证循环，每次 sky 操作必遵）
4. 继续 `reference/platform-ops.md` 或用户指定的测试场景；**未指定时直接 Read `reference/scenarios/bilibili.md`（禁止询问）**
