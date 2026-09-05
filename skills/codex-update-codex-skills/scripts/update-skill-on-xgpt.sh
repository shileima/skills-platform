#!/usr/bin/env bash
set -euo pipefail

SKILL_NAME="${1:-}"
ZIP_PATH="${2:-}"
SPACE_ID="${3:-SP57785706e8f74b84}"

if [ -z "$SKILL_NAME" ]; then
  echo "usage: $0 <skill-name> [zip-path] [space-id]" >&2
  echo "example: $0 codex-catdesk-new-task" >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/resolve-cua-root.sh
source "$SCRIPT_DIR/lib/resolve-cua-root.sh"
CUA_ROOT="$(resolve_cua_root)"

if [ -z "$ZIP_PATH" ]; then
  echo "packing → desktop..." >&2
  ZIP_PATH="$(bash "$SCRIPT_DIR/pack-to-desktop.sh" "$SKILL_NAME")"
  echo "zip: $ZIP_PATH" >&2
fi

if [ ! -f "$ZIP_PATH" ]; then
  echo "zip not found: $ZIP_PATH" >&2
  exit 1
fi

bash "$CUA_ROOT/scripts/daemon.sh" start >/dev/null
CUA_ROUTER_ENSURE_CHROME=auto bash "$CUA_ROOT/scripts/ensure-ready.sh" >/dev/null
bash "$CUA_ROOT/scripts/exec.sh" 'nodeRepl.write("ok")' >/dev/null
bash "$CUA_ROOT/scripts/exec.sh" -t 20000 "await (await import('$CUA_ROOT/scripts/computer-use-client.mjs')).setupComputerUseRuntime({ globals: globalThis }); nodeRepl.write('bootstrapped')" >/dev/null

JS_SKILL=$(python3 - <<'PY' "$SKILL_NAME"
import json, sys
print(json.dumps(sys.argv[1], ensure_ascii=False))
PY
)
JS_ZIP=$(python3 - <<'PY' "$ZIP_PATH"
import json, sys
print(json.dumps(sys.argv[1], ensure_ascii=False))
PY
)
JS_SPACE=$(python3 - <<'PY' "$SPACE_ID"
import json, sys
print(json.dumps(sys.argv[1], ensure_ascii=False))
PY
)
MODULE_PATH="$(python3 - <<'PY' "$SCRIPT_DIR/update-skill-on-xgpt.mjs"
import pathlib, sys
print(pathlib.Path(sys.argv[1]).resolve().as_posix())
PY
)"

RUNNER="$(mktemp -t update-skill-xgpt.XXXXXX.mjs)"
cat >"$RUNNER" <<EOF
await (async () => {
  try {
    const { updateSkillOnXgpt } = await import('file://${MODULE_PATH}');
    const result = await updateSkillOnXgpt({
      skillName: ${JS_SKILL},
      zipPath: ${JS_ZIP},
      spaceId: ${JS_SPACE},
    });
    nodeRepl.write(JSON.stringify(result));
  } catch (e) {
    nodeRepl.write(JSON.stringify({ ok: false, step: "exception", reason: String(e) }));
  }
})();
EOF

OUTPUT="$(bash "$CUA_ROOT/scripts/exec.sh" -t 180000 -f "$RUNNER")"
rm -f "$RUNNER"

echo "$OUTPUT"

OK="$(python3 - <<'PY' "$OUTPUT"
import json, sys
try:
    data = json.loads(sys.argv[1].strip().split("\n")[-1])
    print("true" if data.get("ok") else "false")
except Exception:
    print("false")
PY
)"

if [ "$OK" != "true" ]; then
  STEP="$(python3 - <<'PY' "$OUTPUT"
import json, sys
try:
    data = json.loads(sys.argv[1].strip().split("\n")[-1])
    print(data.get("step", "unknown"))
except Exception:
    print("unknown")
PY
)"
  echo "failed at step: $STEP" >&2
  exit 1
fi
