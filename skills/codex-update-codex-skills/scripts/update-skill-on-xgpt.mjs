import {
  findIdx,
  findImportButtonCandidates,
  findImportButtonIdx,
  findLine,
  findSkillCardIdx,
  findSkillSearchIdx,
  important,
  idxFromLine,
  isCreateSkillDialog,
  isOpenFileDialog,
  isPublishDialog,
  isSkillConfigPage,
  isSkillDetailPage,
  isSkillsListPage,
  urlOf,
  zipTypeAheadPrefix,
} from "./lib/xgpt-ax.mjs";

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

export async function updateSkillOnXgpt({ skillName, zipPath, spaceId }) {
  const skillsUrl = `https://xgpt.sankuai.com/space/${spaceId}/agent/skills`;
  const typeAhead = zipTypeAheadPrefix(zipPath, skillName);

  async function refresh() {
    return ax.get("com.google.Chrome", { refresh: true });
  }

  async function navigateToSkillsList() {
    await refresh();
    await sky.press_key({ app: "com.google.Chrome", key: "Escape" });
    await sleep(400);
    let s = await refresh();
    if (isSkillsListPage(urlOf(s.text))) return s;

    const lines = s.text.split("\n");
    const addrLine = findLine(lines, /settable, string.*地址和搜索栏/);
    const addrIdx = idxFromLine(addrLine) || findIdx(lines, /settable, string.*地址/) || 10;

    await sky.click({ app: "com.google.Chrome", element_index: addrIdx });
    await sleep(200);
    await sky.press_key({ app: "com.google.Chrome", key: "Command+a" });
    await sleep(100);
    await sky.type_text({ app: "com.google.Chrome", text: skillsUrl });
    await sky.press_key({ app: "com.google.Chrome", key: "Return" });
    await sleep(3500);
    return refresh();
  }

  async function searchSkillCard(skill) {
    let s = await navigateToSkillsList();
    let lines = s.text.split("\n");
    let cardIdx = findSkillCardIdx(lines, skill);
    if (cardIdx) return { ok: true, cardIdx, s };

    const searchIdx = findSkillSearchIdx(lines);
    if (!searchIdx) return { ok: false, s, lines };

    await sky.click({ app: "com.google.Chrome", element_index: searchIdx });
    await sleep(300);
    await sky.type_text({ app: "com.google.Chrome", text: skill });
    await sleep(1500);
    s = await refresh();
    lines = s.text.split("\n");
    cardIdx = findSkillCardIdx(lines, skill);
    return { ok: !!cardIdx, cardIdx, s, lines };
  }

  async function clickEditToConfig() {
    const s = await refresh();
    const lines = s.text.split("\n");
    const editIdx = findIdx(lines, /按钮 编辑/);
    if (!editIdx) {
      return {
        ok: false,
        step: "find-edit-button",
        reason: "未找到「编辑」按钮",
        url: urlOf(s.text),
        hints: important(lines, /编辑|Skill|发布/),
      };
    }
    await sky.click({ app: "com.google.Chrome", element_index: editIdx });
    await sleep(2500);
    const s2 = await refresh();
    const url = urlOf(s2.text);
    if (!url.includes("/config")) {
      return {
        ok: false,
        step: "open-config-page",
        reason: "点击编辑后未进入 /config 配置页",
        url,
        hints: important(s2.text.split("\n"), /导入|发布|编辑|Skill/),
      };
    }
    return { ok: true, s: s2 };
  }

  async function openConfigPage() {
    let s = await refresh();
    let url = urlOf(s.text);

    // 已在目标 Skill 配置页，直接继续
    if (isSkillConfigPage(url) && s.text.includes(skillName)) {
      return { ok: true, s };
    }

    // 在目标 Skill 详情页 → 点编辑
    if (isSkillDetailPage(url) && s.text.includes(skillName)) {
      return clickEditToConfig();
    }

    // 其他页面（含错误 Skill 的 config/detail）→ 回清单页搜索目标卡片
    const found = await searchSkillCard(skillName);
    if (!found.ok || !found.cardIdx) {
      return {
        ok: false,
        step: "find-skill-card",
        reason: "技能清单页未找到同名技能卡片",
        skillName,
        url: urlOf(found.s.text),
        hints: important(found.lines || found.s.text.split("\n"), new RegExp(skillName.split("-")[0])),
      };
    }

    await sky.click({ app: "com.google.Chrome", element_index: found.cardIdx });
    await sleep(2000);
    return clickEditToConfig();
  }

  async function openImportUploadDialog() {
    let s = await refresh();
    let lines = s.text.split("\n");

    if (isCreateSkillDialog(lines)) {
      return { ok: true, s };
    }

    const candidates = findImportButtonCandidates(lines);
    if (!candidates.length) {
      return {
        ok: false,
        step: "find-import-button",
        reason: "配置页未找到「导入」工具栏 icon",
        url: urlOf(s.text),
        hints: important(lines, /按钮|上架|下架|发布|Skill/),
      };
    }

    let clickedIdx = null;
    for (const idx of candidates) {
      await refresh();
      await sky.click({ app: "com.google.Chrome", element_index: idx });
      await sleep(1200);
      s = await refresh();
      lines = s.text.split("\n");

      if (isCreateSkillDialog(lines)) {
        clickedIdx = idx;
        break;
      }

      // 误点 AI 助手等浮层 → Escape 关闭后继续试下一个候选
      if (/AI助手|助手|发送消息/.test(s.text)) {
        await sky.press_key({ app: "com.google.Chrome", key: "Escape" });
        await sleep(500);
        s = await refresh();
        lines = s.text.split("\n");
      }
    }

    if (!clickedIdx) {
      return {
        ok: false,
        step: "open-import-dialog",
        reason: "点击导入 icon 后未出现「创建Skill」弹层",
        url: urlOf(s.text),
        tried: candidates,
        hints: important(lines, /创建Skill|AI助手|导入|Github/),
      };
    }

    const uploadTabIdx = findIdx(lines, /单选按钮 上传/);
    if (uploadTabIdx) {
      await sky.click({ app: "com.google.Chrome", element_index: uploadTabIdx });
      await sleep(800);
      s = await refresh();
    }

    return { ok: true, s };
  }

  async function pickZipInOpenDialog() {
    let s = await refresh();
    let lines = s.text.split("\n");

    if (!isOpenFileDialog(lines)) {
      return {
        ok: false,
        step: "file-dialog",
        reason: "未出现 macOS 原生「打开」文件选择框",
        hints: important(lines, /打开|上传|立即/),
      };
    }

    const desktopIdx = findIdx(lines, /row \(selectable\) 桌面$/);
    const zipVisible = lines.some((l) => l.includes(typeAhead) && /\.zip/i.test(l));
    if (desktopIdx && !zipVisible) {
      await sky.click({ app: "com.google.Chrome", element_index: desktopIdx });
      await sleep(1500);
      s = await refresh();
      lines = s.text.split("\n");
    }

    const listViewIdx = findIdx(lines, /ListView|列表视图/);
    if (listViewIdx) {
      await sky.click({ app: "com.google.Chrome", element_index: listViewIdx });
      await sleep(300);
      await sky.type_text({ app: "com.google.Chrome", text: typeAhead });
      await sleep(800);
      s = await refresh();
      lines = s.text.split("\n");
    }

    const openLine = findLine(lines, /OKButton|按钮.*打开/);
    const openDisabled = /disabled/.test(openLine || "");
    const openIdx = openLine ? parseInt(openLine.match(/^\s*(\d+)/)?.[1], 10) : null;

    if (!openIdx || openDisabled) {
      return {
        ok: false,
        step: "select-zip-file",
        reason: "未能选中 zip 或「打开」按钮仍 disabled",
        zipPath,
        typeAhead,
        openLine,
        hints: important(lines, /codex|zip|打开|Desktop|桌面|selected/),
      };
    }

    await sky.click({ app: "com.google.Chrome", element_index: openIdx });
    await sleep(4000);
    s = await refresh();
    if (!urlOf(s.text).includes("/config")) {
      return {
        ok: false,
        step: "after-upload",
        reason: "选中 zip 后未回到配置页",
        url: urlOf(s.text),
        hints: important(s.text.split("\n"), /config|Skill|SKILL|发布/),
      };
    }
    return { ok: true, s };
  }

  async function publishSkill() {
    let s = await refresh();
    let lines = s.text.split("\n");

    const publishIdx = findIdx(lines, /按钮 发布/);
    if (!publishIdx) {
      return {
        ok: false,
        step: "find-publish-button",
        reason: "未找到右上角「发布」按钮",
        url: urlOf(s.text),
        hints: important(lines, /发布|Skill/),
      };
    }

    await sky.click({ app: "com.google.Chrome", element_index: publishIdx });
    await sleep(1500);
    s = await refresh();
    lines = s.text.split("\n");

    if (!isPublishDialog(lines)) {
      return {
        ok: false,
        step: "open-publish-dialog",
        reason: "点击发布后未出现「发布配置」弹层",
        url: urlOf(s.text),
        hints: important(lines, /发布Skill|发布配置|版本号/),
      };
    }

    const confirmIdx = findIdx(lines, /按钮.*发布Skill/);
    if (!confirmIdx) {
      return {
        ok: false,
        step: "find-publish-confirm",
        reason: "未找到「发布Skill」确认按钮",
        url: urlOf(s.text),
        hints: important(lines, /发布Skill|发布配置|版本号/),
      };
    }

    const versionLine = findLine(lines, /版本号.*Value:/);
    await sky.click({ app: "com.google.Chrome", element_index: confirmIdx });
    await sleep(5000);
    s = await refresh();
    lines = s.text.split("\n");

    const published = /当前展示为最新版本|发布成功|已发布/.test(s.text);
    const latestVersion = findLine(lines, /当前展示为最新版本/);

    return {
      ok: published,
      step: published ? "done" : "publish-verify",
      skillName,
      zipPath,
      url: urlOf(s.text),
      published,
      version: latestVersion || versionLine || null,
      hints: published ? [] : important(lines, /发布|成功|失败|版本|Skill/),
    };
  }

  // ── 主流程 ──
  const configResult = await openConfigPage();
  if (!configResult.ok) return configResult;

  let s = configResult.s;

  const importResult = await openImportUploadDialog();
  if (!importResult.ok) return importResult;
  s = importResult.s;

  const uploadBtnIdx = findIdx(s.text.split("\n"), /按钮 立即上传/);
  if (!uploadBtnIdx) {
    return {
      ok: false,
      step: "find-upload-button",
      reason: "「创建Skill」弹层内未找到「立即上传」",
      url: urlOf(s.text),
      hints: important(s.text.split("\n"), /上传|创建Skill|导入/),
    };
  }

  await refresh();
  await sky.click({ app: "com.google.Chrome", element_index: uploadBtnIdx });
  await sleep(1500);

  const pickResult = await pickZipInOpenDialog();
  if (!pickResult.ok) return pickResult;

  return publishSkill();
}
