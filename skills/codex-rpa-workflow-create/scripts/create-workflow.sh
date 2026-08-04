#!/usr/bin/env bash
set -euo pipefail

NAME="${1:-}"
if [ -z "$NAME" ]; then
  echo "usage: $0 <workflow-name>" >&2
  exit 2
fi

SKILL_ROOT="${CUA_ROUTER_INSTALL_DIR:-${HOME}/.automan/skills/cua-router-basic}"
if [ ! -f "$SKILL_ROOT/SKILL.md" ]; then
  SKILL_ROOT="${HOME}/.cursor/skills/cua-router-basic"
fi
if [ ! -f "$SKILL_ROOT/SKILL.md" ]; then
  echo "cua-router-basic not installed. Run its install-remote.sh first." >&2
  exit 1
fi

bash "$SKILL_ROOT/scripts/daemon.sh" start >/dev/null
bash "$SKILL_ROOT/scripts/exec.sh" 'nodeRepl.write("ok")' >/dev/null
bash "$SKILL_ROOT/scripts/exec.sh" -t 20000 "await (await import('$SKILL_ROOT/scripts/computer-use-client.mjs')).setupComputerUseRuntime({ globals: globalThis }); nodeRepl.write('bootstrapped')" >/dev/null

JS_NAME=$(python3 - <<'PY' "$NAME"
import json, sys
print(json.dumps(sys.argv[1], ensure_ascii=False))
PY
)

bash "$SKILL_ROOT/scripts/exec.sh" -t 120000 "
await (async () => {
  const workflowName = ${JS_NAME};
  function axHasLabel(line, label) {
    return new RegExp(label.split('').join('\\\\s*')).test(line);
  }
  function idxFromLine(line) {
    return line ? parseInt(line.match(/^\\s*(\\d+)/)?.[1]) : null;
  }
  function urlOf(text) {
    return (text.match(/URL: ([^\\s,\\n]+)/) || [, ''])[1];
  }
  function important(lines, re) {
    return lines.filter(l => re.test(l)).slice(0, 80);
  }

  const s0 = await sky.get_app_state({ app: 'com.google.Chrome', disableDiff: true });
  const addrLine = s0.text.split('\\n').find(l => /settable, string/.test(l) && /地址/.test(l));
  const addrIdx = idxFromLine(addrLine) || 10;
  await sky.set_value({ app: 'com.google.Chrome', element_index: addrIdx, value: 'https://rpa.sankuai.com/rpa/chat' });
  await sky.press_key({ app: 'com.google.Chrome', key: 'Return' });
  await new Promise(r => setTimeout(r, 3000));

  const s1 = await sky.get_app_state({ app: 'com.google.Chrome', disableDiff: true });
  if (!s1.text.includes('rpa.sankuai.com') || !s1.text.includes('工作流')) {
    nodeRepl.write(JSON.stringify({ ok: false, step: 'open-rpa-home', reason: '未进入 RPA 首页或未发现工作流导航', url: urlOf(s1.text), hints: important(s1.text.split('\\n'), /工作流|RPA|登录|403|401/) }));
    return;
  }

  const lines1 = s1.text.split('\\n');
  const wfLine = lines1.find(l => l.includes('工作流') && /按钮|链接|link|button/i.test(l));
  const wfIdx = idxFromLine(wfLine);
  if (!wfIdx) {
    nodeRepl.write(JSON.stringify({ ok: false, step: 'find-workflow-nav', reason: '未找到左侧工作流按钮', hints: important(lines1, /工作流/) }));
    return;
  }
  await sky.click({ app: 'com.google.Chrome', element_index: wfIdx });
  await new Promise(r => setTimeout(r, 2000));

  const s2 = await sky.get_app_state({ app: 'com.google.Chrome', disableDiff: true });
  const lines2 = s2.text.split('\\n');
  if (!(s2.text.includes('/rpa/workflow') || s2.text.includes('新建工作流'))) {
    nodeRepl.write(JSON.stringify({ ok: false, step: 'enter-workflow-list', reason: '点击工作流后未进入列表', url: urlOf(s2.text), hints: important(lines2, /工作流|新建/) }));
    return;
  }

  const newLine = lines2.find(l => l.includes('新建工作流') && l.includes('按钮'));
  const newIdx = idxFromLine(newLine);
  if (!newIdx) {
    nodeRepl.write(JSON.stringify({ ok: false, step: 'find-new-workflow-button', reason: '未找到新建工作流按钮', hints: important(lines2, /新建|工作流|plus/) }));
    return;
  }
  await sky.click({ app: 'com.google.Chrome', element_index: newIdx });
  await new Promise(r => setTimeout(r, 1500));

  const s3 = await sky.get_app_state({ app: 'com.google.Chrome', disableDiff: true });
  const lines3 = s3.text.split('\\n');
  const nameLine = lines3.find(l => l.includes('文本栏') && l.includes('例如：自动登录签到'));
  const nameIdx = idxFromLine(nameLine);
  if (!nameIdx) {
    nodeRepl.write(JSON.stringify({ ok: false, step: 'find-name-input', reason: '未找到名称输入框', hints: important(lines3, /新建工作流|名称|例如|创建工作流/) }));
    return;
  }
  await sky.set_value({ app: 'com.google.Chrome', element_index: nameIdx, value: workflowName });
  await new Promise(r => setTimeout(r, 500));

  const s4 = await sky.get_app_state({ app: 'com.google.Chrome', disableDiff: true });
  const lines4 = s4.text.split('\\n');
  const createLine = lines4.find(l => l.includes('按钮') && l.includes('创建工作流') && !l.includes('disabled'));
  const createIdx = idxFromLine(createLine);
  if (!createIdx) {
    nodeRepl.write(JSON.stringify({ ok: false, step: 'create-button-disabled', reason: '创建工作流按钮不可用', nameFilled: s4.text.includes(workflowName), hints: important(lines4, /名称|创建工作流|该字段|必填/) }));
    return;
  }
  await sky.click({ app: 'com.google.Chrome', element_index: createIdx });
  await new Promise(r => setTimeout(r, 4000));

  const s5 = await sky.get_app_state({ app: 'com.google.Chrome', disableDiff: true });
  const lines5 = s5.text.split('\\n');
  const canvasLine = lines5.findIndex(l => l.includes('编辑器容器'));
  const area = canvasLine >= 0 ? lines5.slice(canvasLine, canvasLine + 100) : [];
  const hasName = s5.text.includes(workflowName);
  const hasStart = area.some(l => l.includes('开始节点'));
  const hasEnd = area.some(l => l.includes('结束节点'));
  const businessHints = area.filter(l => /打开网页|输入文本|点击|延迟|Cookie|验证元素/.test(l));
  const emptyWorkflow = hasName && canvasLine >= 0 && hasStart && hasEnd && businessHints.length === 0;

  nodeRepl.write(JSON.stringify({
    ok: emptyWorkflow,
    step: 'verify-empty-workflow',
    name: workflowName,
    url: urlOf(s5.text),
    hasName,
    hasEditor: canvasLine >= 0,
    hasStart,
    hasEnd,
    businessHints,
    emptyWorkflow
  }));
})()
"
