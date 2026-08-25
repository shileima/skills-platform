# 前置依赖：cua-router-basic

本技能所有浏览器自动化均通过 `cua-router-basic` 提供的 `sky.*` API 完成（由 `scripts/exec.sh` 调用 `/exec`，运行时自动注入 `sky` / `ax`）。**不得**绕过依赖直接操作 Chrome。

## 检查是否已就绪

`SKILL_DIR` = 本技能目录；`CUA_ROUTER_SKILL_ROOT`（下称 `SKILL_ROOT`）= cua-router-basic 安装路径。

```bash
SKILL_DIR="${WORKFLOW_SKILL_DIR:-/path/to/codex-workflow-command-test}"
bash "$SKILL_DIR/scripts/ensure-ready.sh"
# 输出 ok 表示 cua-router-basic 已就绪
```

或手动：

```bash
SKILL_ROOT="${CUA_ROUTER_INSTALL_DIR:-${HOME}/.automan/claude-code-agents/cua-agent/skills/cua-router-basic}"
[ -f "$SKILL_ROOT/SKILL.md" ] || SKILL_ROOT="${HOME}/.cursor/skills/cua-router-basic"
[ -f "$SKILL_ROOT/SKILL.md" ] || SKILL_ROOT="${HOME}/.automan/skills/cua-router-basic"

test -f "$SKILL_ROOT/SKILL.md" && test -x "$SKILL_ROOT/vendor/codex/bin/codex"
echo "SKILL_ROOT=$SKILL_ROOT"

bash "$SKILL_ROOT/scripts/ensure-ready.sh"
```

**未就绪判定**（满足任一即需安装）：

- `$SKILL_ROOT/SKILL.md` 不存在
- `$SKILL_ROOT/vendor/codex/bin/codex` 不可执行
- `cua.sh get_app_state` 失败

## 未安装时：远程一键安装

```bash
curl -fsSL https://raw.githubusercontent.com/shileima/cua-router-basic/main/scripts/install-remote.sh | bash -s -- --version 0.4.18 --force
```

> 若技能目录已存在但仅缺 vendor，可改用：
> `bash "$SKILL_ROOT/scripts/install-full.sh" --vendor-mode auto`

## 首次授权

首次在本机使用 Computer Use 时，若系统尚未授权辅助功能 + 屏幕录制：

```bash
bash "$SKILL_ROOT/scripts/daemon.sh" authorize
```

## 安装后验证

```bash
bash "$SKILL_DIR/scripts/ensure-ready.sh"
```

验证失败时：**停止后续步骤**，排查安装日志并重试；**不得**在未就绪状态下调用 `sky.*`。

## 就绪后

1. 读取 `$SKILL_ROOT/SKILL.md`，遵循其 `/exec` 运行时规范
2. 确认 cua-router 服务已运行（`daemon.sh start`）
3. 阅读 **`reference/sky-runtime.md`**（`/exec` 步骤批次、Chrome 前台、共享 helper）
4. 阅读 **`reference/ax-verify.md`**（动作-验证循环，每次 sky 操作必遵）
5. 继续 `reference/platform-ops.md` 或用户指定的测试场景；**未指定时直接 Read `reference/scenarios/bilibili.md`（禁止询问）**

**sky 批次前 Shell 前台**（`run-workflow-hosted.sh` 默认会自动执行；也可手动）：

```bash
bash "$SKILL_DIR/scripts/lib/ensure-chrome-front.sh"
```
