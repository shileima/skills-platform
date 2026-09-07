/** AX Tree 解析与 XGPT 页面元素定位（基于 codex-catdesk-new-task 实测稳定策略） */

export function idxFromLine(line) {
  return line ? parseInt(line.match(/^\s*(\d+)/)?.[1], 10) : null;
}

export function urlOf(text) {
  return (text.match(/URL: ([^\s,\n]+)/) || [, ""])[1];
}

export function important(lines, re, limit = 80) {
  return lines.filter((l) => re.test(l)).slice(0, limit);
}

export function findLine(lines, re) {
  return lines.find((l) => re.test(l));
}

export function findIdx(lines, re) {
  return idxFromLine(findLine(lines, re));
}

export function findAllIdx(lines, re) {
  return lines
    .filter((l) => re.test(l))
    .map((l) => idxFromLine(l))
    .filter((n) => n != null);
}

/**
 * 配置页工具栏「导入」icon（向上箭头 tray，非 AI 助手 robot）。
 * 工具栏顺序（实测）：AI助手 | 导入↑ | 编辑 | 历史 | 锁 | … | 下架/上架 | 发布
 * AX 均为无 label「按钮」；导入 icon ≈ 下架/上架 前第 5 个 idx（shelf−5），
 * 是 shelf 前工具栏簇中第 2 个（第 1 个是 AI 助手，误点会打开 AI 助手面板）。
 */
export function findToolbarIconButtons(lines, shelfIdx) {
  const icons = [];
  for (const line of lines) {
    const m = line.match(/^\s+(\d+) 按钮$/);
    if (!m) continue;
    const idx = parseInt(m[1], 10);
    if (idx >= shelfIdx - 8 && idx < shelfIdx) icons.push(idx);
  }
  return icons.sort((a, b) => a - b);
}

function findShelfButtonIdx(lines) {
  return findIdx(lines, /按钮.*上架/) || findIdx(lines, /按钮.*下架/);
}

export function findImportButtonIdx(lines) {
  const labeled = findIdx(lines, /按钮 导入/);
  if (labeled) return labeled;

  const shelfIdx = findShelfButtonIdx(lines);
  if (!shelfIdx) return null;

  // 主策略：导入 icon 在 shelf 前固定偏移（catdesk 实测 shelf=36 → 导入=31）
  const byOffset = shelfIdx - 5;
  if (findLine(lines, new RegExp(`^\\s+${byOffset} 按钮$`))) return byOffset;

  // 次策略：shelf 前工具栏簇中第 2 个无 label 按钮（跳过 AI 助手）
  const icons = findToolbarIconButtons(lines, shelfIdx);
  if (icons.length >= 2) return icons[1];
  if (icons.length >= 1) return icons[0];
  return null;
}

/** 按优先级返回「导入」icon 候选 idx；排除 AI 助手（工具栏簇第 1 个） */
export function findImportButtonCandidates(lines) {
  const shelfIdx = findShelfButtonIdx(lines);
  if (!shelfIdx) return [];

  const candidates = [];
  const primary = findImportButtonIdx(lines);
  if (primary) candidates.push(primary);

  const icons = findToolbarIconButtons(lines, shelfIdx);
  // 跳过 icons[0]（AI 助手），只试导入及之后的工具栏 icon
  for (const idx of icons.slice(1)) {
    if (!candidates.includes(idx)) candidates.push(idx);
  }
  for (const delta of [-5, -4, -6]) {
    const idx = shelfIdx + delta;
    if (idx > 0 && findLine(lines, new RegExp(`^\\s+${idx} 按钮$`)) && !candidates.includes(idx)) {
      candidates.push(idx);
    }
  }
  return candidates;
}

export function isSkillsListPage(url) {
  return /\/agent\/skills\/?$/.test(url.replace(/^https?:\/\//, ""));
}

export function isSkillDetailPage(url) {
  return /\/agent\/skills\/cskill-[^/]+\/?$/.test(url.replace(/^https?:\/\//, ""));
}

export function isSkillConfigPage(url) {
  return /\/agent\/skills\/cskill-[^/]+\/config/.test(url.replace(/^https?:\/\//, ""));
}

/** 清单页搜索框（排除配置页「搜索文件或目录」） */
export function findSkillSearchIdx(lines) {
  return findIdx(lines, /文本栏.*搜索\.\.\./) || findIdx(lines, /^[^\n]*搜索\.\.\.[^\n]*$/);
}

/** 技能卡片：清单页上为「按钮 <skillName> 技能 …」；兜底匹配文本行 */
export function findSkillCardIdx(lines, skillName) {
  const card = findIdx(lines, new RegExp(`按钮 ${escapeRegExp(skillName)}`));
  if (card) return card;
  const textLine = findLine(lines, new RegExp(`文本 ${escapeRegExp(skillName)}$`));
  if (textLine) {
    const textIdx = idxFromLine(textLine);
    for (let i = textIdx - 1; i >= Math.max(0, textIdx - 5); i--) {
      if (/按钮/.test(lines[i]) && lines[i].includes(skillName)) {
        return idxFromLine(lines[i]);
      }
    }
  }
  return null;
}

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

export function zipTypeAheadPrefix(zipPath, skillName) {
  const base = (zipPath.split("/").pop() || "").replace(/\.zip$/i, "");
  if (!base) return skillName;
  // 优先用 skill 名前缀做 type-ahead（如 codex-catdesk-new-task_0.0.1 → codex-catdesk-new-task）
  const fromName = base.split("_")[0];
  return fromName || skillName;
}

export function isOpenFileDialog(lines) {
  return lines.some((l) => /open-panel|表单 Description: 打开|Window: "打开"/.test(l));
}

export function isCreateSkillDialog(lines) {
  return lines.some((l) => /创建Skill|container 创建Skill/.test(l));
}

export function isPublishDialog(lines) {
  return lines.some((l) => /发布配置|发布Skill/.test(l));
}
