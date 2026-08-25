#!/usr/bin/env bash
# cua-router-basic 就绪探针（主验证：/cua get_app_state）

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/resolve-cua-root.sh
source "$SKILL_DIR/scripts/lib/resolve-cua-root.sh"

CUA_ROOT="$(resolve_cua_root)"
echo "SKILL_ROOT=$CUA_ROOT"

bash "$CUA_ROOT/scripts/ensure-ready.sh" >/dev/null

echo "ok"
