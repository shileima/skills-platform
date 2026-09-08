#!/usr/bin/env bash
# 解析 cua-router-basic 安装路径

resolve_cua_root() {
  local root="${CUA_ROUTER_INSTALL_DIR:-}"
  if [ -n "$root" ] && [ -f "$root/SKILL.md" ]; then
    echo "$root"
    return 0
  fi
  for candidate in \
    "${HOME}/.automan/claude-code-agents/cua-agent/skills/cua-router-basic" \
    "${HOME}/.automan/skills/cua-router-basic" \
    "${HOME}/.cursor/skills/cua-router-basic"; do
    if [ -f "$candidate/SKILL.md" ]; then
      echo "$candidate"
      return 0
    fi
  done
  echo "cua-router-basic not found" >&2
  return 1
}
