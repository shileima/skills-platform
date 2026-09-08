#!/usr/bin/env bash
# 主入口：instruction-plan → 构建节点 → 剪贴板 → 粘贴到空编排工作流

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLAN_FILE=""
WORKFLOW_NAME=""
BUILD_ONLY=0
NO_CREATE=0
NO_PASTE=0
CLEAR_AND_PASTE=0

usage() {
  cat <<EOF
usage: $0 --plan <instruction-plan.json> [options]

options:
  --plan <file>           指令计划 JSON（必填，含 instructionPlan 数组）
  --workflow-name <name>  工作流名称（无打开的工作流时用于创建）
  --build-only            仅构建节点 JSON，不粘贴
  --no-create             不自动创建空工作流（要求已在配置页）
  --clear-and-paste       清空 canvas 业务节点后重新粘贴（修复迭代，不新建工作流）
  --no-paste              构建 + 包装剪贴板，但不执行粘贴

instruction-plan.json 示例见 reference/examples/bilibili-plan.json
EOF
  exit 2
}

while [ $# -gt 0 ]; do
  case "$1" in
    --plan) PLAN_FILE="$2"; shift 2 ;;
    --workflow-name) WORKFLOW_NAME="$2"; shift 2 ;;
    --build-only) BUILD_ONLY=1; shift ;;
    --no-create) NO_CREATE=1; shift ;;
    --clear-and-paste) CLEAR_AND_PASTE=1; NO_CREATE=1; shift ;;
    --no-paste) NO_PASTE=1; shift ;;
    -h|--help) usage ;;
    *) echo "unknown arg: $1" >&2; usage ;;
  esac
done

[ -n "$PLAN_FILE" ] || usage
[ -f "$PLAN_FILE" ] || { echo "plan file not found: $PLAN_FILE" >&2; exit 2; }

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/rpa-wf-gen.XXXXXX")"
trap 'rm -rf "$WORK_DIR"' EXIT

NODES_FILE="$WORK_DIR/nodes.json"
CLIPBOARD_FILE="$WORK_DIR/clipboard.txt"

echo "==> 构建节点 JSON"
node "$SKILL_DIR/scripts/build-nodes.mjs" "$PLAN_FILE" "$NODES_FILE"

echo "==> 校验 formData 字段"
node "$SKILL_DIR/scripts/validate-built-nodes.mjs" "$PLAN_FILE"

echo "==> 包装剪贴板"
node "$SKILL_DIR/scripts/wrap-clipboard.mjs" "$NODES_FILE" "$CLIPBOARD_FILE"

if [ "$BUILD_ONLY" -eq 1 ]; then
  cp "$NODES_FILE" "${PLAN_FILE%.json}.nodes.json" 2>/dev/null || cp "$NODES_FILE" "./workflow.nodes.json"
  cp "$CLIPBOARD_FILE" "${PLAN_FILE%.json}.clipboard.txt" 2>/dev/null || true
  echo "{\"ok\":true,\"buildOnly\":true,\"nodes\":\"$NODES_FILE\",\"clipboard\":\"$CLIPBOARD_FILE\"}"
  exit 0
fi

bash "$SKILL_DIR/scripts/ensure-ready.sh" >/dev/null

# 若无工作流页则创建
if [ "$NO_CREATE" -eq 0 ]; then
  WF_NAME="${WORKFLOW_NAME:-}"
  if [ -z "$WF_NAME" ]; then
    WF_NAME=$(python3 - <<PY
import json, datetime
with open("$PLAN_FILE") as f:
    d = json.load(f)
print(d.get("workflowName") or f"编排自动生成-{datetime.datetime.now():%Y%m%d-%H%M}")
PY
)
  fi

  CREATE_SKILL="${HOME}/.cursor/skills/codex-rpa-workflow-generate"
  if [ -f "$CREATE_SKILL/scripts/create-empty-workflow.sh" ]; then
    echo "==> 创建空编排工作流: $WF_NAME"
    CREATE_OUT=$(bash "$CREATE_SKILL/scripts/create-empty-workflow.sh" "$WF_NAME" | tail -1)
    echo "$CREATE_OUT"
  elif [ -f "${HOME}/.cursor/skills/codex-rpa-workflow-create/scripts/create-workflow.sh" ]; then
    echo "==> 创建空编排工作流: $WF_NAME"
    CREATE_OUT=$(bash "${HOME}/.cursor/skills/codex-rpa-workflow-create/scripts/create-workflow.sh" "$WF_NAME" | tail -1)
    echo "$CREATE_OUT"
  else
    echo "warn: codex-rpa-workflow-create 未安装，假定已在空编排页" >&2
  fi
fi

if [ "$NO_PASTE" -eq 1 ]; then
  echo "{\"ok\":true,\"noPaste\":true,\"clipboard\":\"$CLIPBOARD_FILE\",\"nodes\":\"$NODES_FILE\"}"
  exit 0
fi

if [ "$CLEAR_AND_PASTE" -eq 1 ]; then
  echo "==> 清空并重贴到现有编排 canvas"
  PASTE_OUT=$(bash "$SKILL_DIR/scripts/repaste-workflow.sh" "$CLIPBOARD_FILE" | tail -1)
else
  echo "==> 粘贴到编排 canvas"
  PASTE_OUT=$(bash "$SKILL_DIR/scripts/paste-workflow.sh" "$CLIPBOARD_FILE" | tail -1)
fi
echo "$PASTE_OUT"

echo ""
echo "==> 生成完成。下一步请激活 codex-workflow-command-test 执行「检查 → 调试 → 修复」"
