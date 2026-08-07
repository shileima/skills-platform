#!/usr/bin/env bash
set -euo pipefail

BASE_NAME="${1:-new-curor-project}"
PROMPT="${2:-帮我新建一个前端工程，功能为简洁功能社区站点}"
CURSOR_APP="com.todesktop.230313mzl4w4u92"

resolve_skill_root() {
  local root="${CUA_ROUTER_INSTALL_DIR:-${HOME}/.automan/claude-code-agents/cua-agent/skills/cua-router-basic}"
  if [ ! -f "$root/SKILL.md" ]; then
    root="${HOME}/.cursor/skills/cua-router-basic"
  fi
  if [ ! -f "$root/SKILL.md" ]; then
    root="${HOME}/.automan/claude-code-agents/cua-agent/skills/cua-router-basic"
  fi
  if [ ! -f "$root/SKILL.md" ]; then
    echo "找不到 cua-router-basic 技能，请先安装该技能" >&2
    exit 1
  fi
  printf '%s\n' "$root"
}

json_escape() {
  python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'
}

js_string() {
  python3 -c 'import json,sys; print(json.dumps(sys.stdin.read(), ensure_ascii=False))'
}

next_available_name() {
  local base="$1"
  if [ ! -e "$HOME/$base" ]; then
    printf '%s\n' "$base"
    return
  fi
  local i=1
  while [ -e "$HOME/$base-$i" ]; do
    i=$((i + 1))
  done
  printf '%s\n' "$base-$i"
}

run_exec() {
  local code="$1"
  bash "$SKILL_ROOT/scripts/exec.sh" -t 120000 "$code"
}

apple_click_menu_new_agents_window() {
  osascript \
    -e 'tell application "Cursor" to activate' \
    -e 'delay 0.3' \
    -e 'tell application "System Events" to tell process "Cursor"' \
    -e 'click menu item "New Agents Window" of menu 1 of menu bar item "文件" of menu bar 1' \
    -e 'end tell'
}

click_new_agent_button() {
  swift -e 'import AppKit; import ApplicationServices; guard let app = NSWorkspace.shared.runningApplications.first(where: { $0.localizedName == "Cursor" }) else { print("NO_CURSOR"); exit(1) }; let ax = AXUIElementCreateApplication(app.processIdentifier); func attr(_ el: AXUIElement,_ a:String)->CFTypeRef?{var v:CFTypeRef?; AXUIElementCopyAttributeValue(el,a as CFString,&v); return v}; func s(_ el:AXUIElement,_ a:String)->String{attr(el,a).map{String(describing:$0)} ?? ""}; func children(_ el:AXUIElement)->[AXUIElement]{attr(el,kAXChildrenAttribute as String) as? [AXUIElement] ?? []}; func pt(_ el:AXUIElement)->CGPoint?{guard let v=attr(el,kAXPositionAttribute as String), CFGetTypeID(v)==AXValueGetTypeID() else{return nil}; var p=CGPoint.zero; AXValueGetValue(v as! AXValue,.cgPoint,&p); return p}; func sz(_ el:AXUIElement)->CGSize?{guard let v=attr(el,kAXSizeAttribute as String), CFGetTypeID(v)==AXValueGetTypeID() else{return nil}; var z=CGSize.zero; AXValueGetValue(v as! AXValue,.cgSize,&z); return z}; var found:AXUIElement?=nil; func walk(_ el:AXUIElement){ if found != nil { return }; let title=s(el,kAXTitleAttribute); let desc=s(el,kAXDescriptionAttribute); if title == "New Agent" || desc == "New Agent" { found=el; return }; for c in children(el){ walk(c) } }; walk(ax); guard let el=found, let p=pt(el), let z=sz(el) else { print("NO_NEW_AGENT"); exit(2) }; let q=CGPoint(x:p.x+z.width/2,y:p.y+z.height/2); let src=CGEventSource(stateID:.hidSystemState); CGEvent(mouseEventSource:src, mouseType:.leftMouseDown, mouseCursorPosition:q, mouseButton:.left)?.post(tap:.cghidEventTap); CGEvent(mouseEventSource:src, mouseType:.leftMouseUp, mouseCursorPosition:q, mouseButton:.left)?.post(tap:.cghidEventTap); print("DONE")'
}

click_project_dropdown_and_new_folder() {
  swift -e 'import AppKit; import ApplicationServices; guard let app = NSWorkspace.shared.runningApplications.first(where: { $0.localizedName == "Cursor" }) else { print("NO_CURSOR"); exit(1) }; let ax = AXUIElementCreateApplication(app.processIdentifier); func attr(_ el: AXUIElement,_ a:String)->CFTypeRef?{var v:CFTypeRef?; AXUIElementCopyAttributeValue(el,a as CFString,&v); return v}; func s(_ el:AXUIElement,_ a:String)->String{attr(el,a).map{String(describing:$0)} ?? ""}; func children(_ el:AXUIElement)->[AXUIElement]{attr(el,kAXChildrenAttribute as String) as? [AXUIElement] ?? []}; func pt(_ el:AXUIElement)->CGPoint?{guard let v=attr(el,kAXPositionAttribute as String), CFGetTypeID(v)==AXValueGetTypeID() else{return nil}; var p=CGPoint.zero; AXValueGetValue(v as! AXValue,.cgPoint,&p); return p}; func sz(_ el:AXUIElement)->CGSize?{guard let v=attr(el,kAXSizeAttribute as String), CFGetTypeID(v)==AXValueGetTypeID() else{return nil}; var z=CGSize.zero; AXValueGetValue(v as! AXValue,.cgSize,&z); return z}; func click(_ el:AXUIElement){let p=pt(el)!; let z=sz(el)!; let q=CGPoint(x:p.x+z.width/2,y:p.y+z.height/2); let src=CGEventSource(stateID:.hidSystemState); CGEvent(mouseEventSource:src, mouseType:.leftMouseDown, mouseCursorPosition:q, mouseButton:.left)?.post(tap:.cghidEventTap); CGEvent(mouseEventSource:src, mouseType:.leftMouseUp, mouseCursorPosition:q, mouseButton:.left)?.post(tap:.cghidEventTap)}; var found:AXUIElement?=nil; func walk(_ el:AXUIElement,_ pred:(AXUIElement)->Bool){ if found != nil { return }; if pred(el){found=el; return}; for c in children(el){walk(c,pred)} }; walk(ax){ e in let role=s(e,kAXRoleAttribute); let title=s(e,kAXTitleAttribute); let desc=s(e,kAXDescriptionAttribute); return role.contains("AXPopUpButton") && !title.contains("Chat actions") && !desc.contains("Chat actions") && !title.contains("main") && !desc.contains("main") && !title.contains("This Mac") && !desc.contains("This Mac") && !title.contains("Composer") && !desc.contains("Composer") }; guard let dropdown=found else { print("NO_DROPDOWN"); exit(2)}; click(dropdown); Thread.sleep(forTimeInterval:0.8); found=nil; walk(ax){ e in s(e,kAXTitleAttribute) == "New Folder" || s(e,kAXDescriptionAttribute) == "New Folder" }; guard let nf=found else { print("NO_NEW_FOLDER"); exit(3)}; click(nf); Thread.sleep(forTimeInterval:1.0); print("DONE")'
}

paste_text() {
  local text="$1"
  osascript \
    -e "set the clipboard to $(printf '%s' "$text" | json_escape)" \
    -e 'tell application "Cursor" to activate' \
    -e 'delay 0.2' \
    -e 'tell application "System Events" to tell process "Cursor"' \
    -e 'keystroke "a" using command down' \
    -e 'delay 0.1' \
    -e 'keystroke "v" using command down' \
    -e 'end tell'
}

SKILL_ROOT="$(resolve_skill_root)"
bash "$SKILL_ROOT/scripts/daemon.sh" start >/dev/null
bash "$SKILL_ROOT/scripts/exec.sh" 'nodeRepl.write("ok")' >/dev/null

open -a "Cursor"
PROJECT_NAME="$(next_available_name "$BASE_NAME")"
apple_click_menu_new_agents_window >/dev/null || true

if ! run_exec '{
  const app = "'"$CURSOR_APP"'";
  await new Promise(r => setTimeout(r, 2500));
  const s = await sky.get_app_state({ app, disableDiff: true });
  if (!s.text.includes("Cursor Agents")) {
    throw new Error("未检测到 Cursor Agents 窗口");
  }
  if (!s.text.includes("Plan, Build")) {
    throw new Error("当前不是新建聊天输入框，可能停在旧会话");
  }
  nodeRepl.write("ready");
}' >/dev/null; then
  click_new_agent_button >/dev/null
  run_exec '{
    const app = "'"$CURSOR_APP"'";
    await new Promise(r => setTimeout(r, 1800));
    const s = await sky.get_app_state({ app, disableDiff: true });
    if (!s.text.includes("Cursor Agents") || !s.text.includes("Plan, Build")) {
      throw new Error("点击 New Agent 后仍未检测到新建聊天输入框");
    }
    nodeRepl.write("ready");
  }' >/dev/null
fi

click_project_dropdown_and_new_folder >/dev/null
paste_text "$PROJECT_NAME"
run_exec '{
  const app = "'"$CURSOR_APP"'";
  await sky.get_app_state({ app, disableDiff: true });
  await sky.press_key({ app, key: "Return" });
  await new Promise(r => setTimeout(r, 3000));
  const s = await sky.get_app_state({ app, disableDiff: true });
  if (s.text.includes("已存在") || s.text.includes("替换")) {
    await sky.press_key({ app, key: "Escape" });
    throw new Error("项目名冲突，请重试，脚本会选择下一个可用后缀");
  }
  nodeRepl.write(JSON.stringify({ ok: true, text: s.text.slice(0, 1000) }));
}' >/dev/null || {
  PROJECT_NAME="$(next_available_name "$BASE_NAME")"
  click_project_dropdown_and_new_folder >/dev/null
  paste_text "$PROJECT_NAME"
  run_exec '{
    const app = "'"$CURSOR_APP"'";
    await sky.get_app_state({ app, disableDiff: true });
    await sky.press_key({ app, key: "Return" });
    await new Promise(r => setTimeout(r, 3000));
    const s = await sky.get_app_state({ app, disableDiff: true });
    if (s.text.includes("已存在") || s.text.includes("替换")) throw new Error("项目名仍冲突");
    nodeRepl.write("created");
  }' >/dev/null
}

paste_text "$PROMPT"
PROMPT_JS="$(printf '%s' "$PROMPT" | js_string)"
PROJECT_JS="$(printf '%s' "$PROJECT_NAME" | js_string)"
run_exec '{
  const app = "'"$CURSOR_APP"'";
  const prompt = '"$PROMPT_JS"';
  const project = '"$PROJECT_JS"';
  await new Promise(r => setTimeout(r, 500));
  let s = await sky.get_app_state({ app, disableDiff: true });
  if (!s.text.includes(prompt)) {
    throw new Error("聊天输入框未包含预期提示词");
  }
  await sky.press_key({ app, key: "Return" });
  await new Promise(r => setTimeout(r, 2000));
  s = await sky.get_app_state({ app, disableDiff: true });
  const started = s.text.includes("Stop generation") || s.text.includes("Planning") || s.text.includes("Working") || s.text.includes("Running") || s.text.includes("Worked") || s.text.includes(prompt);
  nodeRepl.write(JSON.stringify({ ok: true, project, prompt, status: started ? "sent" : "submitted" }));
}'
