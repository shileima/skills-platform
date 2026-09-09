# 节点 JSON 结构规范

编排工作流在 TipTap 编辑器中以 JSON 数组存储。本技能**只生成 `rpaNode`**，不包含 `startNode` / `endNode`（空工作流已存在）。

> 全部 56 种编辑器节点的 type/tag/字段/用法见 [editor-nodes.md](editor-nodes.md)。

## rpaNode 结构

```json
{
  "type": "rpaNode",
  "attrs": {
    "tag": "OpenUrl",
    "nodeId": "<21位字母数字>",
    "nodeConfigState": "done",
    "data": {
      "skillName": "打开网页(web)",
      "unionId": "OpenUrl",
      "id": 1,
      "commandType": 1,
      "showDesc": "打开网页 url:${url}",
      "toolDesc": "打开网页 url:https://www.bilibili.com",
      "formData": { }
    }
  }
}
```

## 元素选择器（不入库 LLM 形式）

`workflowElementId` **无需平台注册**，采用 `elementSourceType: "elementAdd"` 的内联 JSON：

- `selector` / `locator.locator` / `element`：同一 JSON 字符串
- `locateModeJsons[].locateMode`：`LLM`
- `locateModeJsons[].locateModeValue`：含 `alias`、`locateMode: LLM`、`modelName: Doubao-Seed-2.0-pro`

构建逻辑见 `scripts/lib/build-nodes.mjs` → `buildSelectorId()`。

## 剪贴板格式

编辑器 `clipboard.ts` 协议：

```
__JSON_DATA__[{type, attrs}, ...]__JSON_DATA__
```

粘贴时编辑器自动重新生成 `nodeId` 并插入当前光标位置。

## 插入位置

空编排工作流：**单击开始节点 → Enter → 在开始节点下方空行 → Cmd+V**。

详见 `codex-workflow-command-test/reference/insert-command.md`。
