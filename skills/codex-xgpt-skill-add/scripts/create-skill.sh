#!/usr/bin/env bash
# 在 xgpt.sankuai.com 创建 Skill 并进入配置页（稳定版：set_value + Tab 失焦 + 确定前重扫 AX）
set -euo pipefail

SKILL_NAME="${1:-skill-test-$(date +%Y%m%d%H%M%S)}"
SKILL_DESC="${2:-test}"
SPACE_ID="${3:-SP57785706e8f74b84}"

SKILL_ROOT="${CUA_ROUTER_INSTALL_DIR:-${HOME}/.automan/claude-code-agents/cua-agent/skills/cua-router-basic}"
if [ ! -f "$SKILL_ROOT/SKILL.md" ]; then
  SKILL_ROOT="${HOME}/.cursor/skills/cua-router-basic"
fi
if [ ! -f "$SKILL_ROOT/SKILL.md" ]; then
  echo "cua-router-basic 未安装，请先安装/更新 cua-router-basic。" >&2
  exit 1
fi

bash "$SKILL_ROOT/scripts/ensure-ready.sh" >/dev/null

JS_NAME=$(python3 - <<'PY' "$SKILL_NAME"
import json, sys
print(json.dumps(sys.argv[1], ensure_ascii=False))
PY
)
JS_DESC=$(python3 - <<'PY' "$SKILL_DESC"
import json, sys
print(json.dumps(sys.argv[1], ensure_ascii=False))
PY
)
JS_SPACE=$(python3 - <<'PY' "$SPACE_ID"
import json, sys
print(json.dumps(sys.argv[1], ensure_ascii=False))
PY
)

echo "开始创建 Skill「${SKILL_NAME}」…" >&2

RESULT="$(bash "$SKILL_ROOT/scripts/exec.sh" -t 120000 "
await (async () => {
  const app = 'com.google.Chrome';
  const skillName = ${JS_NAME};
  const skillDesc = ${JS_DESC};
  const spaceId = ${JS_SPACE};
  const sleep = ms => new Promise(r => setTimeout(r, ms));

  async function refresh() {
    return ax.get(app, { refresh: true });
  }

  function scanConfirm(s) {
    return ax.findAllIdx(s.text, '确', '定', '按钮');
  }

  function urlOf(state) {
    return state.url || (state.text.match(/URL: ([^\\s,\\n]+)/) || [, ''])[1] || '';
  }

  async function locateOne(keywords, label) {
    const s = await refresh();
    const matches = ax.findAllIdx(s.text, ...keywords);
    if (matches.length !== 1) {
      throw new Error(label + ': matches=' + matches.length + ' ' + JSON.stringify(matches.slice(0, 3)));
    }
    return { s, match: matches[0] };
  }

  async function fillField(keywords, value, label) {
    let { match } = await locateOne(keywords, label);
    await sky.click({ app, element_index: match.idx });
    await sleep(250);
    ({ match } = await locateOne(keywords, label + '-重定位'));
    await sky.set_value({ app, element_index: match.idx, value });
    await sleep(300);
    // Tab 失焦：促使 React 表单同步内部 state（仅 set_value 不足以提交）
    await sky.press_key({ app, key: 'Tab' });
    await sleep(300);
    const s = await refresh();
    const fieldLabel = label === '名称' ? '* Skill名称' : '* Skill简介';
    const line = s.text.split('\\n').find(l => l.includes(fieldLabel) && (l.includes('Value') || l.includes('文本')));
    return { idx: match.idx, line, ok: (line || '').includes(value) };
  }

  async function rescanConfirm() {
    let s = await refresh();
    let candidates = scanConfirm(s);
    if (candidates.length === 1) return { s, candidates, scrolled: false };
    const desc = ax.findAllIdx(s.text, '* Skill简介', '文本');
    if (desc.length >= 1) {
      await sky.scroll({ app, element_index: desc[0].idx, direction: 'down', pages: 2 });
      await sleep(400);
      s = await refresh();
      candidates = scanConfirm(s);
    }
    return { s, candidates, scrolled: true };
  }

  async function ensureSkillsListPage() {
    let s = await refresh();
    const url = urlOf(s);
    if (url.includes('/agent/skills') && !url.includes('/config') && s.text.includes('按钮 新建')) {
      return s;
    }

    const skillNav = ax.findAllIdx(s.text, 'Skill 技能');
    if (skillNav.length === 1) {
      await sky.click({ app, element_index: skillNav[0].idx });
      for (let i = 0; i < 15; i++) {
        await sleep(500);
        s = await refresh();
        if (urlOf(s).includes('/agent/skills') && !urlOf(s).includes('/config') && s.text.includes('按钮 新建')) {
          return s;
        }
      }
    }

    const expertNav = ax.findAllIdx(s.text, '按钮', ' 专家');
    if (expertNav.length === 1 && !url.includes('/agent/skills')) {
      await sky.click({ app, element_index: expertNav[0].idx });
      for (let i = 0; i < 15; i++) {
        await sleep(500);
        s = await refresh();
        if (s.text.includes('Skill 技能')) break;
      }
      const skillNav2 = ax.findAllIdx(s.text, 'Skill 技能');
      if (skillNav2.length === 1) {
        await sky.click({ app, element_index: skillNav2[0].idx });
        for (let i = 0; i < 15; i++) {
          await sleep(500);
          s = await refresh();
          if (urlOf(s).includes('/agent/skills') && s.text.includes('按钮 新建')) return s;
        }
      }
    }

    const skillsUrl = 'https://xgpt.sankuai.com/space/' + spaceId + '/agent/skills';
    const addrMatches = ax.findAllIdx(s.text, 'settable', 'string', '地址');
    if (addrMatches.length >= 1) {
      const addrIdx = addrMatches[0].idx;
      await sky.click({ app, element_index: addrIdx });
      await sleep(200);
      await sky.set_value({ app, element_index: addrIdx, value: skillsUrl });
      await sleep(200);
      await sky.press_key({ app, key: 'Return' });
      for (let i = 0; i < 15; i++) {
        await sleep(500);
        s = await refresh();
        if (s.text.includes('按钮 新建')) return s;
      }
    }

    throw new Error('未能进入技能清单页: ' + urlOf(s));
  }

  try {
    await ensureSkillsListPage();

    let s = await refresh();
    if (!s.text.includes('创建Skill')) {
      const { match: newBtn } = await locateOne(['按钮 新建'], '新建');
      await sky.click({ app, element_index: newBtn.idx });
      for (let i = 0; i < 12; i++) {
        await sleep(400);
        s = await refresh();
        if (s.text.includes('创建Skill')) break;
      }
      if (!s.text.includes('创建Skill')) {
        throw new Error('创建Skill 弹层未打开');
      }
    }

    const confirmBaseline = scanConfirm(await refresh());
    const nameResult = await fillField(['* Skill名称', '文本栏'], skillName, '名称');
    const descResult = await fillField(['* Skill简介', '文本'], skillDesc, '简介');

    s = await refresh();
    const confirmAfterFill = scanConfirm(s);
    const indexShifted = confirmBaseline[0]?.idx !== confirmAfterFill[0]?.idx;

    let { candidates: confirmCandidates, scrolled } = await rescanConfirm();
    if (confirmCandidates.length !== 1) {
      ({ candidates: confirmCandidates, scrolled } = await rescanConfirm());
    }
    if (confirmCandidates.length !== 1) {
      throw new Error('确定按钮重扫描失败: ' + JSON.stringify({ confirmBaseline, confirmAfterFill, confirmCandidates }));
    }

    const confirmTarget = confirmCandidates[0];
    await sky.click({ app, element_index: confirmTarget.idx });

    let result = {
      ok: false,
      skillName,
      skillDesc,
      confirmBaseline,
      confirmAfterFill,
      indexShifted,
      confirmTarget,
      scrolled,
      nameResult,
      descResult,
    };

    for (let i = 0; i < 30; i++) {
      await sleep(1000);
      s = await refresh();
      const url = urlOf(s);
      if (url.includes('/config')) {
        result = {
          ...result,
          ok: true,
          url,
          preview: ax.summarize(s, { keywords: [skillName, 'config'], maxLines: 8 }),
        };
        break;
      }
      if (!s.text.includes('创建Skill') && s.text.includes(skillName)) {
        result = { ...result, ok: true, url, note: 'skill visible' };
        break;
      }
      if (i === 29) {
        result = {
          ...result,
          stillOpen: s.text.includes('创建Skill'),
          url,
        };
      }
    }

    nodeRepl.write(JSON.stringify(result));
  } catch (error) {
    const s = await refresh().catch(() => ({ text: '', url: '' }));
    nodeRepl.write(JSON.stringify({
      ok: false,
      skillName,
      error: error instanceof Error ? error.message : String(error),
      url: urlOf(s),
      hints: ax.linesMatching(s.text, /创建Skill|Skill名称|Skill简介|确|取消|错误|失败/, { limit: 12 }),
    }));
  }
})()
")"

printf '%s\n' "$RESULT"

python3 - "$RESULT" <<'PY'
import json
import sys

result = json.loads(sys.argv[1])
if result.get("ok") is not True:
    raise SystemExit(1)
PY
