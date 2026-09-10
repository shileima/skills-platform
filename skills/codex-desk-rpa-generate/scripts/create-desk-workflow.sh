#!/usr/bin/env bash
# Automan Desktop：自动化助手 → 新建 RPA 工作流 → 进入编排区
set -euo pipefail

WORKFLOW_NAME="${1:-codex生成工作流-「date」}"
RESUME="${2:-}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

CUA_ROOT="${CUA_ROUTER_INSTALL_DIR:-${HOME}/.automan/claude-code-agents/cua-agent/skills/cua-router-basic}"
if [ ! -f "$CUA_ROOT/SKILL.md" ]; then
  CUA_ROOT="${HOME}/.automan/skills/cua-router-basic"
fi
if [ ! -f "$CUA_ROOT/SKILL.md" ]; then
  CUA_ROOT="${HOME}/.cursor/skills/cua-router-basic"
fi
if [ ! -f "$CUA_ROOT/SKILL.md" ]; then
  echo '{"ok":false,"reason":"cua-router-basic not installed"}' >&2
  exit 1
fi

bash "$CUA_ROOT/scripts/ensure-ready.sh" >/dev/null

PART1_ARGS=(part1 "$WORKFLOW_NAME")
if [ "$RESUME" = "--resume" ]; then
  PART1_ARGS+=(--resume)
fi

python3 "$SCRIPT_DIR/build_replay_plan.py" "${PART1_ARGS[@]}" | bash "$CUA_ROOT/scripts/replay.sh" -t 600000
python3 "$SCRIPT_DIR/build_replay_plan.py" part2 | bash "$CUA_ROOT/scripts/replay.sh" -t 120000

WF_NAME="$WORKFLOW_NAME" python3 -c 'import json, os; print(json.dumps({"ok": True, "name": os.environ["WF_NAME"], "inEditor": True}, ensure_ascii=False))'
