#!/usr/bin/env bash
# 创建空编排工作流（shell 层 pbcopy，避免 exec.sh 内 pbcopy 失败）

set -euo pipefail

NAME="${1:-}"
if [ -z "$NAME" ]; then
  echo "usage: $0 <workflow-name>" >&2
  exit 2
fi

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/resolve-cua-root.sh
source "$SKILL_DIR/scripts/lib/resolve-cua-root.sh"

CUA_ROOT="$(resolve_cua_root)"
bash "$CUA_ROOT/scripts/daemon.sh" start >/dev/null
bash "$SKILL_DIR/scripts/ensure-ready.sh" >/dev/null

printf '%s' "$NAME" | /usr/bin/pbcopy

JS_NAME=$(python3 - <<'PY' "$NAME"
import json, sys
print(json.dumps(sys.argv[1], ensure_ascii=False))
PY
)

bash "$CUA_ROOT/scripts/exec.sh" -t 120000 "
await (async () => {
  const workflowName = ${JS_NAME};
  function idxFromLine(line) {
    return line ? parseInt(line.match(/^\\s*(\\d+)/)?.[1]) : null;
  }
  function urlOf(text) {
    return (text.match(/URL: ([^\\s,\\n]+)/) || [, ''])[1];
  }
  function important(lines, re) {
    return lines.filter(l => re.test(l)).slice(0, 80);
  }
  async function shellPaste(elementIndex) {
    await sky.click({ app: 'com.google.Chrome', element_index: elementIndex });
    await new Promise(r => setTimeout(r, 300));
    await sky.press_key({ app: 'com.google.Chrome', key: 'Command+a' });
    await new Promise(r => setTimeout(r, 100));
    await sky.press_key({ app: 'com.google.Chrome', key: 'Command+v' });
    await new Promise(r => setTimeout(r, 700));
  }

  const s0 = await sky.get_app_state({ app: 'com.google.Chrome', disableDiff: true });
  const addrLine = s0.text.split('\\n').find(l => /settable, string/.test(l) && /地址/.test(l));
  const addrIdx = idxFromLine(addrLine) || 10;
  await sky.set_value({ app: 'com.google.Chrome', element_index: addrIdx, value: 'https://rpa.sankuai.com/rpa/chat' });
  await sky.press_key({ app: 'com.google.Chrome', key: 'Return' });
  await new Promise(r => setTimeout(r, 3000));

  const s1 = await sky.get_app_state({ app: 'com.google.Chrome', disableDiff: true });
  if (!s1.text.includes('rpa.sankuai.com') || !s1.text.includes('工作流')) {
    nodeRepl.write(JSON.stringify({ ok: false, step: 'open-rpa-home', url: urlOf(s1.text) }));
    return;
  }

  const lines1 = s1.text.split('\\n');
  const wfLine = lines1.find(l => l.includes('工作流') && /按钮|链接|link|button/i.test(l));
  const wfIdx = idxFromLine(wfLine);
  if (!wfIdx) {
    nodeRepl.write(JSON.stringify({ ok: false, step: 'find-workflow-nav' }));
    return;
  }
  await sky.click({ app: 'com.google.Chrome', element_index: wfIdx });
  await new Promise(r => setTimeout(r, 2000));

  const s2 = await sky.get_app_state({ app: 'com.google.Chrome', disableDiff: true });
  const lines2 = s2.text.split('\\n');
  const newLine = lines2.find(l => l.includes('新建工作流') && l.includes('按钮'));
  const newIdx = idxFromLine(newLine);
  if (!newIdx) {
    nodeRepl.write(JSON.stringify({ ok: false, step: 'find-new-workflow-button', url: urlOf(s2.text) }));
    return;
  }
  await sky.click({ app: 'com.google.Chrome', element_index: newIdx });
  await new Promise(r => setTimeout(r, 1500));

  const s3 = await sky.get_app_state({ app: 'com.google.Chrome', disableDiff: true });
  const lines3 = s3.text.split('\\n');
  const nameLine = lines3.find(l => l.includes('文本栏') && l.includes('例如：自动登录签到'));
  const nameIdx = idxFromLine(nameLine);
  if (!nameIdx) {
    nodeRepl.write(JSON.stringify({ ok: false, step: 'find-name-input' }));
    return;
  }
  await shellPaste(nameIdx);

  const s4 = await sky.get_app_state({ app: 'com.google.Chrome', disableDiff: true });
  const lines4 = s4.text.split('\\n');
  const createLine = lines4.find(l => l.includes('按钮') && l.includes('创建工作流') && !l.includes('disabled'));
  const createIdx = idxFromLine(createLine);
  if (!createIdx) {
    nodeRepl.write(JSON.stringify({ ok: false, step: 'create-button-disabled', nameFilled: s4.text.includes(workflowName) }));
    return;
  }
  await sky.click({ app: 'com.google.Chrome', element_index: createIdx });
  await new Promise(r => setTimeout(r, 4000));

  const s5 = await sky.get_app_state({ app: 'com.google.Chrome', disableDiff: true });
  const lines5 = s5.text.split('\\n');
  const canvasLine = lines5.findIndex(l => l.includes('编辑器容器'));
  const area = canvasLine >= 0 ? lines5.slice(canvasLine, canvasLine + 100) : [];
  const emptyWorkflow = s5.text.includes(workflowName) && canvasLine >= 0
    && area.some(l => l.includes('开始节点'))
    && area.some(l => l.includes('结束节点'))
    && !area.some(l => /打开网页|输入文本|点击/.test(l));

  nodeRepl.write(JSON.stringify({
    ok: emptyWorkflow,
    name: workflowName,
    url: urlOf(s5.text),
    emptyWorkflow,
  }));
})();
"
