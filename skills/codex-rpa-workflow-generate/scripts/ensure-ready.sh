#!/usr/bin/env bash
# cua-router-basic 就绪探针

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/resolve-cua-root.sh
source "$SKILL_DIR/scripts/lib/resolve-cua-root.sh"

CUA_ROOT="$(resolve_cua_root)"
bash "$CUA_ROOT/scripts/daemon.sh" start
bash "$CUA_ROOT/scripts/cua.sh" get_app_state '{"app":"Finder"}' >/dev/null
echo "ok"
