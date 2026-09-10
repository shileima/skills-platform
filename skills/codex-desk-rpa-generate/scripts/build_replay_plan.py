#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""根据当前 AX 探测结果生成 replay plan（不含「创建」步，创建在弹窗打开后单独探测）。"""

import json
import os
import subprocess
import sys


def find_cua_root() -> str:
    """解析 cua-router-basic 安装目录。"""
    candidates = [
        os.environ.get("CUA_ROUTER_INSTALL_DIR", ""),
        os.path.expanduser("~/.automan/claude-code-agents/cua-agent/skills/cua-router-basic"),
        os.path.expanduser("~/.automan/skills/cua-router-basic"),
        os.path.expanduser("~/.cursor/skills/cua-router-basic"),
    ]
    for root in candidates:
        if root and os.path.isfile(os.path.join(root, "SKILL.md")):
            return root
    raise SystemExit(json.dumps({"ok": False, "reason": "cua-router-basic not installed"}))


def probe_ax(cua_root: str, app: str) -> dict:
    """刷新 AX，返回唯一「新建」行与是否在 RPA 页。"""
    exec_cmd = f"""
const app = {json.dumps(app)};
const s = await ax.get(app, {{ refresh: true }});
const lines = s.text.split("\\n");
const newLines = lines.filter(l => /^\\s*\\d+\\s+按钮 新建\\s*$/.test(l)).map(l => l.trim());
const onRpa = s.text.includes("我的工作流") || (s.url && String(s.url).includes("flow-rpa-agent"));
nodeRepl.write(JSON.stringify({{ newLines, onRpa, url: s.url || "" }}));
"""
    proc = subprocess.run(
        ["bash", os.path.join(cua_root, "scripts/exec.sh"), "-t", "90000", exec_cmd],
        capture_output=True,
        text=True,
    )
    if proc.returncode != 0:
        raise SystemExit(json.dumps({"ok": False, "step": "probe-ax", "stderr": proc.stderr[-500:]}))
    line = proc.stdout.strip().split("\n")[-1]
    return json.loads(line)


def probe_create_button(cua_root: str, app: str) -> str | None:
    """弹窗打开后探测唯一「按钮 创建」整行（不含单选按钮）。"""
    exec_cmd = f"""
const app = {json.dumps(app)};
const s = await ax.get(app, {{ refresh: true }});
const lines = s.text.split("\\n");
const createLines = lines.filter(l => /^\\s*\\d+\\s+按钮 创建\\s*$/.test(l)).map(l => l.trim());
nodeRepl.write(JSON.stringify({{ createLines }}));
"""
    proc = subprocess.run(
        ["bash", os.path.join(cua_root, "scripts/exec.sh"), "-t", "90000", exec_cmd],
        capture_output=True,
        text=True,
    )
    if proc.returncode != 0:
        return None
    try:
        data = json.loads(proc.stdout.strip().split("\n")[-1])
    except json.JSONDecodeError:
        return None
    lines = data.get("createLines") or []
    if len(lines) == 1:
        return lines[0].strip().replace("\t", " ")
    return None


def build_part1(workflow_name: str, app: str, probe: dict, force_skip_nav: bool) -> dict:
    """生成至填写名称为止的步骤。"""
    new_kw = probe.get("newLines") or []
    on_rpa = probe.get("onRpa") or force_skip_nav

    if len(new_kw) != 1:
        raise SystemExit(
            json.dumps(
                {
                    "ok": False,
                    "step": "locate-new-button",
                    "reason": f"期望 1 条「按钮 新建」行，实际 {len(new_kw)}",
                    "candidates": new_kw[:10],
                },
                ensure_ascii=False,
            )
        )

    new_target = new_kw[0].strip().replace("\t", " ")

    if not on_rpa:
        steps = [
            {"id": "activate-automan", "action": "activate_app", "app": app, "verify": ["新建任务"]},
            {
                "id": "click-automation-assistant",
                "action": "click",
                "app": app,
                "target": ["按钮", "自动化助手"],
                "verify": ["我的工作流"],
            },
        ]
    else:
        steps = [{"id": "ensure-rpa", "action": "activate_app", "app": app, "verify": ["我的工作流"]}]

    name_verify = workflow_name[:8] if len(workflow_name) > 8 else workflow_name
    steps.extend(
        [
            {
                "id": "click-new-workflow",
                "action": "click",
                "app": app,
                "target": [new_target],
                "verify": ["新建工作流"],
            },
            {
                "id": "input-workflow-name",
                "action": "input_text",
                "app": app,
                "target": ["文本栏", "例如：自动登录签到、批量表单填写"],
                "value": workflow_name,
                "strategies": ["set_value", "type_text"],
                "verify": [name_verify],
            },
        ]
    )
    return {"version": 1, "name": "codex-desk-rpa-generate-part1", "steps": steps}


def build_part2(app: str, create_line: str) -> dict:
    """点击创建并校验编排区。"""
    return {
        "version": 1,
        "name": "codex-desk-rpa-generate-part2",
        "steps": [
            {
                "id": "click-create",
                "action": "click",
                "app": app,
                "target": [create_line],
                "verify": ["编排区"],
            }
        ],
    }


def main() -> None:
    if len(sys.argv) < 2:
        print("usage: build_replay_plan.py <mode> ...", file=sys.stderr)
        sys.exit(2)
    mode = sys.argv[1]
    app = "/Applications/Automan Desktop.app"
    cua = find_cua_root()

    if mode == "part1":
        workflow_name = sys.argv[2] if len(sys.argv) > 2 else 'codex生成工作流-「date」'
        force_skip = sys.argv[3] == "--resume" if len(sys.argv) > 3 else False
        probe = probe_ax(cua, app)
        plan = build_part1(workflow_name, app, probe, force_skip)
        print(json.dumps(plan, ensure_ascii=False))
    elif mode == "part2":
        create_line = probe_create_button(cua, app)
        if not create_line:
            raise SystemExit(
                json.dumps(
                    {"ok": False, "step": "locate-create-button", "reason": "弹窗内未找到唯一「按钮 创建」行"},
                    ensure_ascii=False,
                )
            )
        print(json.dumps(build_part2(app, create_line), ensure_ascii=False))
    else:
        sys.exit(2)


if __name__ == "__main__":
    main()
