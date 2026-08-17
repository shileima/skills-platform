#!/usr/bin/env bash
# diagram-design 内网安装脚本 — 安装到 code-governance profile
set -euo pipefail

S3_BASE="${S3_BASE:-https://s3plus.sankuai.com/aiagent-bucket/diagram-design-resources}"
AGENT_ID="${AGENT_ID:-code-governance}"
SKILL_NAME="diagram-design"
SKILL_DIR="${HOME}/.automan/claude-code-agents/${AGENT_ID}/skills/${SKILL_NAME}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

FORCE=0
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
  esac
done

echo "[diagram-design] fetching version metadata…"
META_JSON="$(curl -fsSL "${S3_BASE}/.meta.json")"
REMOTE_VERSION="$(python3 -c "import json,sys; print(json.load(sys.stdin).get('version',''))" <<<"${META_JSON}")"
if [[ -z "${REMOTE_VERSION}" ]]; then
  echo "[diagram-design] ERROR: invalid .meta.json" >&2
  exit 1
fi

if [[ -f "${SKILL_DIR}/.meta.json" && "${FORCE}" -eq 0 ]]; then
  LOCAL_VERSION="$(python3 -c "import json; print(json.load(open('${SKILL_DIR}/.meta.json')).get('version',''))" 2>/dev/null || true)"
  if [[ "${LOCAL_VERSION}" == "${REMOTE_VERSION}" && -f "${SKILL_DIR}/SKILL.md" ]]; then
    echo "[diagram-design] already at ${REMOTE_VERSION}, skip"
    exit 0
  fi
fi

ARCHIVE="${SKILL_NAME}_${REMOTE_VERSION}.zip"
echo "[diagram-design] downloading ${ARCHIVE}…"
curl -fsSL "${S3_BASE}/${ARCHIVE}" -o "${TMP_DIR}/${ARCHIVE}"

echo "[diagram-design] extracting to ${SKILL_DIR}…"
mkdir -p "$(dirname "${SKILL_DIR}")"
rm -rf "${SKILL_DIR}"
mkdir -p "${SKILL_DIR}"
unzip -q "${TMP_DIR}/${ARCHIVE}" -d "${SKILL_DIR}"

if [[ ! -f "${SKILL_DIR}/SKILL.md" ]]; then
  echo "[diagram-design] ERROR: SKILL.md missing after extract" >&2
  exit 1
fi

echo "[diagram-design] installed ${REMOTE_VERSION} → ${SKILL_DIR}"
