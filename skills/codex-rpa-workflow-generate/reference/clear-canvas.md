# 清空编排 canvas 业务节点

修复迭代（`--clear-and-paste`）时，需先清空现有业务节点再重贴。脚本：`scripts/clear-canvas-nodes.sh`。

## 策略 A：批量清空（首选）

```
1. 确认 Chrome 已在 rpa.sankuai.com 编排工作流配置页
2. 点击「编排区」Tab 聚焦编辑器
3. 单击选中「开始节点」
4. Control+a 全选编辑器内容
5. Delete 删除选中内容
```

> **必须**从「开始节点」起选，不要点业务节点或其他行；全选后 Delete 可一次性清掉中间全部业务指令，开始/结束节点通常保留。

## 策略 B：单行删除（兜底 / 删某一行）

全选删除后仍有残留，或只需删除**某一行**节点时：

```
1. 将鼠标 hover 到目标节点行（人工操作）；自动化 exec 环境无 `sky.hover`，**单击节点行等效**
2. 等待该行右侧出现「删除」图标（仅 hover/选中时可见）
3. 全量抓 AX Tree，定位并点击「删除」按钮
4. 验证该行已从 canvas 消失
```

> 删除图标**默认隐藏**，必须先 hover 到节点行才会暴露；禁止在未 hover 时盲搜删除按钮。

脚本兜底逻辑：策略 A 执行后若 `remainingCount > 0`，自动对残留业务节点**从后往前**逐条执行策略 B。

## 用法

```bash
SKILL_ROOT="${HOME}/.cursor/skills/codex-rpa-workflow-generate"

# 仅清空
bash "$SKILL_ROOT/scripts/clear-canvas-nodes.sh"

# 清空 + 重贴（修复迭代）
bash "$SKILL_ROOT/scripts/generate-workflow.sh" \
  --plan /tmp/instruction-plan.json \
  --clear-and-paste
```

## sky 自动化片段（批量清空）

```js
{
  const app = "com.google.Chrome";
  const lines = (await sky.get_app_state({ app, disableDiff: true })).text.split("\n");
  const startLine = lines.find(l => l.includes("开始节点") && /^\s*\d+\s+text/.test(l.replace(/\t/g, " ")));
  const startIdx = parseInt(startLine.match(/^\s*(\d+)/)[1]);

  await sky.click({ app, element_index: startIdx });
  await new Promise(r => setTimeout(r, 400));
  await sky.press_key({ app, key: "Control+a" });
  await new Promise(r => setTimeout(r, 350));
  await sky.press_key({ app, key: "Delete" });
}
```

## sky 自动化片段（单行删除）

```js
{
  const app = "com.google.Chrome";
  const nodeIdx = 75; // canvas 节点行的 element_index

  await sky.click({ app, element_index: nodeIdx }); // exec 无 sky.hover，单击等效 hover
  await new Promise(r => setTimeout(r, 450));

  const s = await sky.get_app_state({ app, disableDiff: true });
  const lines = s.text.split("\n");
  const lineNo = lines.findIndex(l => parseInt(l.match(/^\s*(\d+)/)?.[1]) === nodeIdx);
  const slice = lines.slice(lineNo, lineNo + 20);
  const delLine = slice.find(l => /删除/.test(l) && /按钮|button|图像/i.test(l));
  const delIdx = delLine ? parseInt(delLine.match(/^\s*(\d+)/)[1]) : null;

  if (!delIdx) throw new Error("hover 后未找到删除按钮");
  await sky.click({ app, element_index: delIdx });
}
```

## 通过标准

- `remainingCount === 0`（无业务节点残留）
- `canvasSummary` 仅剩开始节点、结束节点及空行提示
- `method` 为 `start-node-control-a-delete` 或 `start-node-bulk-then-row-delete`
- 清空失败时 **禁止** 新建工作流；先排查是否在配置页、是否已选中开始节点

## 清空后粘贴

清空成功后，`paste-workflow.sh` 会：

1. 选中开始节点
2. `Command+v` 粘贴剪贴板 JSON 节点

因此开始节点必须保留；若全选删除误删开始节点，需回到工作流列表重建空工作流。
