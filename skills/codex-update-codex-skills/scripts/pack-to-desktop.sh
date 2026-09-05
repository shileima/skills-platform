#!/usr/bin/env bash
set -euo pipefail

SKILL_NAME="${1:-}"
if [ -z "$SKILL_NAME" ]; then
  echo "usage: $0 <skill-name>" >&2
  echo "example: $0 codex-catdesk-new-task" >&2
  exit 2
fi

SKILLS_PLATFORM_ROOT="${SKILLS_PLATFORM_ROOT:-${HOME}/code/skills-platform}"
SKILLDEV="${SKILLS_PLATFORM_ROOT}/bin/skilldev.mjs"
SKILL_JSON="${SKILLS_PLATFORM_ROOT}/skills/${SKILL_NAME}/skill.json"

if [ ! -f "$SKILLDEV" ]; then
  echo "skills-platform not found at $SKILLS_PLATFORM_ROOT" >&2
  exit 1
fi

if [ ! -f "$SKILL_JSON" ]; then
  echo "skill source not found: $SKILLS_PLATFORM_ROOT/skills/$SKILL_NAME" >&2
  exit 1
fi

node "$SKILLDEV" pack "$SKILL_NAME" >/dev/null

read -r META_NAME VERSION < <(
  python3 - <<'PY' "$SKILL_JSON"
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    meta = json.load(f)
print(meta.get("automan", {}).get("metaName") or meta["name"], meta["version"])
PY
)

ZIP_NAME="${META_NAME}_${VERSION}.zip"
SRC_ZIP="${SKILLS_PLATFORM_ROOT}/dist/${ZIP_NAME}"
DEST_ZIP="${HOME}/Desktop/${ZIP_NAME}"

if [ ! -f "$SRC_ZIP" ]; then
  echo "pack output missing: $SRC_ZIP" >&2
  exit 1
fi

cp -f "$SRC_ZIP" "$DEST_ZIP"
echo "$DEST_ZIP"
