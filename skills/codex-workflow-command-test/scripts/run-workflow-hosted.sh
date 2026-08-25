#!/usr/bin/env bash
# 通过 cua-router /exec 执行 Bots 工作流 sky 自动化步骤。
#
# 用法：
#   bash scripts/run-workflow-hosted.sh <<'JS'
#   await sky.get_app_state({ app, disableDiff: true });
#   emitResult({ step: "ready" });
#   JS
#
#   bash scripts/run-workflow-hosted.sh -f scripts/steps/my-step.mjs
#
# 环境变量：
#   SKIP_CHROME_FRONT=1  跳过 Chrome 前台激活
#   CUA_ROUTER_INSTALL_DIR  覆盖 cua-router-basic 路径

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/resolve-cua-root.sh
source "$SKILL_DIR/scripts/lib/resolve-cua-root.sh"

CUA_ROOT="$(resolve_cua_root)"
export CUA_ROUTER_SKILL_ROOT="$CUA_ROOT"
export WORKFLOW_SKILL_DIR="$SKILL_DIR"

bash "$CUA_ROOT/scripts/ensure-ready.sh" >/dev/null

if [ "${SKIP_CHROME_FRONT:-0}" != "1" ]; then
  bash "$SKILL_DIR/scripts/lib/ensure-chrome-front.sh" >/dev/null 2>&1 || true
fi

RUNTIME_MJS="$SKILL_DIR/scripts/workflow-runtime.mjs"
RUN_JS="${TMPDIR:-/tmp}/workflow-hosted.$$.$RANDOM.mjs"
trap 'rm -f "$RUN_JS"' EXIT

USER_CODE=""
if [ "${1:-}" = "-f" ]; then
  shift
  USER_CODE="$(cat "${1:?缺少脚本路径}")"
elif [ "${1:-}" = "-e" ]; then
  shift
  USER_CODE="$1"
else
  USER_CODE="$(cat)"
  if [ -z "$USER_CODE" ]; then
    echo "用法: run-workflow-hosted.sh [-f script.mjs] 或 heredoc/stdin 传入 JS 步骤体" >&2
    exit 1
  fi
fi

python3 - "$RUN_JS" "$RUNTIME_MJS" "$USER_CODE" <<'PY'
import sys
from pathlib import Path

out_path = Path(sys.argv[1])
runtime_path = Path(sys.argv[2]).resolve()
user_code = sys.argv[3]

runtime_uri = runtime_path.as_uri()
wrapper = f'''const {{ setupWorkflowRuntime, emitResult }} = await import("{runtime_uri}");

const rt = setupWorkflowRuntime();
const {{
  sky, app, sleep, mustIdx, linesOf, findAllIdx, findIdx, axHasLabel, axButtonIdx,
  findCmdTab, findSearchIdx, waitSearchIdx, defocusCanvas, findCanvasNode,
  listCanvasNodes, dblclickWebResult, dblclickWebResultLoose, reorderNodeCutPaste,
  fixClickNodeLLM, insertAfterAnchor, saveDialog, configLLMScoped, fillAsciiField,
  debugRunOnce, assertCanSave, assertCanSaveOpenUrl,
}} = rt;

{user_code}
'''
out_path.write_text(wrapper, encoding="utf-8")
PY

bash "$CUA_ROOT/scripts/exec.sh" -t 120000 -f "$RUN_JS"
