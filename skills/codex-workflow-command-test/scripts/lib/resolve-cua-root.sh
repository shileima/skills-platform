#!/usr/bin/env bash
# 解析 cua-router-basic 安装路径（Cursor / Automan / Codex 共用）

resolve_cua_root() {
  local root="${CUA_ROUTER_INSTALL_DIR:-${HOME}/.automan/claude-code-agents/cua-agent/skills/cua-router-basic}"
  if [ ! -f "$root/SKILL.md" ]; then
    root="${HOME}/.cursor/skills/cua-router-basic"
  fi
  if [ ! -f "$root/SKILL.md" ]; then
    root="${HOME}/.automan/skills/cua-router-basic"
  fi
  if [ ! -f "$root/SKILL.md" ]; then
    echo "找不到 cua-router-basic 技能，请先安装：curl -fsSL https://raw.githubusercontent.com/shileima/cua-router-basic/main/scripts/install-remote.sh | bash -s -- --version 0.4.18 --force" >&2
    return 1
  fi
  printf '%s\n' "$root"
}

resolve_workflow_skill_dir() {
  local dir
  dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  printf '%s\n' "$dir"
}
