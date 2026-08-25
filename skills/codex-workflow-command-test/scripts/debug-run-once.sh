#!/usr/bin/env bash
# 终检通过后唯一一次「调试 → 运行」

set -euo pipefail
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

bash "$SKILL_DIR/scripts/run-workflow-hosted.sh" <<'JS'
await sky.get_app_state({ app, disableDiff: true });
emitResult(await debugRunOnce());
JS
