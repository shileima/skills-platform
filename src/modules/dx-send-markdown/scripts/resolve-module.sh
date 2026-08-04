#!/usr/bin/env bash
# Resolve shared module path: staged copy under skill, or repo src/modules in dev.
resolve_module_root() {
  local skill_dir="$1"
  local module_name="$2"
  local staged="$skill_dir/modules/$module_name"
  if [ -f "$staged/MODULE.md" ] || [ -d "$staged/scripts" ]; then
    printf '%s\n' "$staged"
    return 0
  fi
  local repo_root
  repo_root="$(cd "$skill_dir/../.." && pwd)"
  local dev="$repo_root/src/modules/$module_name"
  if [ -f "$dev/MODULE.md" ] || [ -d "$dev/scripts" ]; then
    printf '%s\n' "$dev"
    return 0
  fi
  echo "找不到模块 $module_name（请先 skilldev build/install 或确认在 skills-platform 仓库内）" >&2
  return 1
}
