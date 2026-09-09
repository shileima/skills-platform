# 编排编辑器节点用法参考

> **来源**：`waimai-qa-aie-fe/modules/base-editor-v3/src/Editor/nodes`（56 个 `node.ts`）  
> **类型定义**：`Editor/types/editor.ts`（`NodeType` / `NodeTag` / `NodeTagToNodeType`）  
> **内置节点**：`Editor/utils/builtInNode.ts`（`BUILT_IN_NODES_MAP`）  
> **校验规则**：`Editor/utils/validator/index.ts`（`nodeValidatorRules`）

本技能**自动生成**仅支持 `rpaNode` 且 `unionId` 在白名单内（见 [§RPA 指令](#rpa-指令)）。其余节点供场景规划、理解编排结构、后续扩展时参考。

---

## 通用 JSON 结构

TipTap 编辑器以 JSON 数组存储工作流。所有节点共享 `attrs` 外壳：

```json
{
  "type": "<TipTap name>",
  "attrs": {
    "tag": "<NodeTag 或 unionId>",
    "icon": "",
    "nodeId": "<21位字母数字>",
    "disabled": false,
    "nodeConfigState": "default|done|error",
    "breakpoints": false,
    "actionType": "",
    "originalData": null,
    "data": {}
  },
  "content": []
}
```

| 概念 | 说明 |
|------|------|
| **type** | TipTap 节点名，对应 `node.ts` 中 `name` 字段 |
| **tag** | 运行时标识；`rpaNode` 的 `attrs.tag` = `unionId`（如 `OpenUrl`） |
| **content** | 仅容器节点有子节点数组 |
| **nodeConfigState** | `done` 表示配置完整；粘贴生成时设为 `done` |

**容器节点**（`node.ts` 定义 `content: '(...)*'`）：可在内部嵌套子节点。

**剪贴板协议**：`__JSON_DATA__[{...}, ...]__JSON_DATA__`（见 `node-schema.md`）。

---

## 节点分类速查

| 分类 | 节点数 | 典型用途 |
|------|--------|---------|
| [流程控制](#流程控制) | 5 | 开始/结束/触发/子流程返回 |
| [AI 能力](#ai-能力) | 18 | 大模型、知识库、意图分类、MCP |
| [操作类](#操作类) | 20 | 变量、代码、HTTP、消息、工作流调用 |
| [逻辑类](#逻辑类) | 9 | IF/循环/并行/异常处理/智能体循环 |
| [RPA 指令](#rpa-指令) | 1 | Web 原子指令（本技能核心） |
| [特殊 RPA 节点](#特殊-rpa-节点) | 3 | 循环元素、断言、RPA Block |

---

## 流程控制

### startNode — 开始节点

| 字段 | 值 |
|------|-----|
| type | `startNode` |
| tag | `Start` |
| 容器 | 否 |
| 自动生成 | 否（空工作流已内置） |

```json
{ "title": "开始节点", "inputList": [] }
```

- **关键字段**：`inputList`（工作流入参）、`formCode`、`formType`
- **使用**：工作流入口，位于文档首位，不可删除
- **插入**：空工作流创建后已存在，无需生成

### endNode — 结束节点

| 字段 | 值 |
|------|-----|
| type | `endNode` |
| tag | `End` |
| 容器 | 否 |
| 自动生成 | 否 |

```json
{ "title": "结束节点" }
```

- **关键字段**：`outputList`（最终输出变量映射）
- **使用**：工作流出口，配置返回值

### triggerNode — 触发器

| 字段 | 值 |
|------|-----|
| type | `triggerNode` |
| tag | `TriggerTask` |
| 容器 | 否 |

```json
{ "title": "触发器" }
```

- **关键字段**（必填）：`triggerType`、`triggerConfig`
- **注意**：`parseHTML`/`renderHTML` 标签为 `startNode`，但 TipTap `name` 为 `triggerNode`

### triggerNodeForNocodb — Nocodb 触发器

| 字段 | 值 |
|------|-----|
| type | `startNode` ⚠️ |
| tag | `Start` |
| 容器 | 否 |

Nocodb 集成变体，TipTap `name` 与 `startNode` 相同。

### returnSubNode — 子流程返回

| 字段 | 值 |
|------|-----|
| type | `returnSubNode` |
| tag | `ReturnSub` |
| 容器 | 否 |

```json
{ "title": "ReturnSub" }
```

- **关键字段**：`outputList`
- **使用**：被调用子工作流的返回点

---

## AI 能力

### llmNode — 大模型

| 字段 | 值 |
|------|-----|
| type | `llmNode` |
| tag | `LLM` |
| 容器 | 否 |

```json
{
  "title": "大模型",
  "outputList": [
    { "name": "result", "type": "String" },
    { "name": "reasoning_content", "type": "String" }
  ],
  "outputType": "markdown"
}
```

- **关键字段**：`modelRef`/`model`、`promptValue`/`prompts`、`systemPromptValue`、`configType`（`form`|`dynamic`）、`context`、`imageUrls`
- **校验**：`configType !== dynamic` 时 `promptValue` 或 `prompts` 必填
- **输出**：`result`、`reasoning_content` + 自定义 `outputList`

### kbNode — 知识库

| type | tag | 输出 |
|------|-----|------|
| `kbNode` | `KnowledgeBase` | `resultList`(Array)、`output`(String) |

- **必填**：`kbId`、`queryStr`
- **可选**：`retrievalType` 决定检索策略字段

### updateKbNode — 更新知识库

| type | tag | 输出 |
|------|-----|------|
| `updateKbNode` | `KnowledgeBaseUpdateTask` | `data`(Object) |

- **关键字段**：`kbId`、`kbUnitId`、`knowledgeType`（`text`|`fileUrl`）

### uiKbNode — 元素库

| type | tag | 输出 |
|------|-----|------|
| `uiKbNode` | `ElementLibraryTask` | `resultList`、`output` |

- **关键字段**：`operationType`、`elementLibraryId`、`strategyConfigId`、`queryStr`

### parameterExtractorNode — 字段提取

| type | tag | 输出 |
|------|-----|------|
| `parameterExtractorNode` | `ParameterExtractor` | `result`(String) |

- **必填**：`text`（待提取文本）
- **可选**：`instruction`、`inputList`

### intentClassifierNode — 意图分类

| type | tag | 容器 |
|------|-----|------|
| `intentClassifierNode` | `IntentClassify` | **是** — `classificationNode|otherNode` |

```json
{
  "title": "意图分类",
  "classifications": [
    { "name": "类别1", "id": "..." },
    { "name": "其他", "id": "..." }
  ]
}
```

- **必填**：`text`、`classifications`
- **子节点**：每个分类对应一个 `classificationNode` 或 `otherNode` 分支

### qaNode — 提问

| type | tag | 容器 |
|------|-----|------|
| `qaNode` | `QuestionAnswer` | **是** |

```json
{ "title": "提问", "answerType": 0, "questionType": 0 }
```

- **必填**：`question`
- **answerType**：0=文本 / 1=选项 / 2=表单
- **输出**：`userResponse`（用户回答）

### ai — AI Task 容器

| type | tag | 容器 |
|------|-----|------|
| `AITask-1` | `AITask-1` | **是** — `node|paragraph` |

```json
{ "title": "AITask", "description": "" }
```

AI 任务编排容器，内部可嵌套任意节点。

### mcpNode — MCP 工具

| type | tag | 容器 |
|------|-----|------|
| `mcpNode` | `MCPTask` | 否 |

- **关键字段**：`mcpInstanceTag`、`toolParamsJson`、`inputList`、`outputList`
- **输出**：由 MCP 工具 schema 动态定义

### longTermMemorySearchTaskNode — 长时记忆查询

| type | tag |
|------|-----|
| `longTermMemorySearchTaskNode` | `LongtermMemorySearchTask` |

- **必填**：`agentUuid`、`query`

### dateProcessNode — 日期和时间处理

| type | tag |
|------|-----|
| `dateProcessNode` | `DateProcess` |

```json
{
  "title": "日期和时间处理",
  "dateStr": "",
  "processType": "DATE_FORMAT",
  "timeZone": "Asia/Shanghai",
  "dateType": "date_string",
  "formatType": "fixed"
}
```

### kbNodes — 知识库 ETL 流水线

| type | tag | 中文名 | 输出 | 关键字段 |
|------|-----|--------|------|---------|
| `createDatasetsNode` | `CreateNewKbDatasetComponentTask` | 新建数据集 | `data` | `sourceType`, `kbId`, `datasetName` |
| `dataAnalysisNode` | `TemplateSourceLoaderComponentTask` | 数据源加载 | `data` | `sourceType`, `sourceParamJson` |
| `faqSegmentNode` | `TemplateFAQLlmSplitterComponentTask` | FAQ LLM 切分 | `data` | `sourceText`, `qaSplitPrompt` |
| `faqTemplateSegmentNode` | `TemplateFAQFormatSplitterComponentTask` | FAQ 模板切分 | `data` | `sourceText` |
| `segmentStorageNode` | `TemplateDataNodePersistComponentTask` | 分段存储 | `data` | `kbId`, `datasetId`, `persistType` |
| `textEmbeddingNode` | `TemplateEmbeddedComponentTask` | 文本向量化 | `data` | `modelName`, `chunkListStr` |
| `textSegmentNode` | `TemplateCommonSplitterComponentTask` | 文本切分 | `output` | `sourceText`, `maxChunkSize`, `chunkOverlap` |

以上均为叶子节点，用于知识库构建流水线串联。

---

## 操作类

### variableNode — 设置变量

| type | tag | 输出 |
|------|-----|------|
| `variableNode` | `DeclareVariable` | 由 `inputList` 定义的变量名 |

```json
{ "title": "设置变量", "outputList": [] }
```

- **关键字段**：`inputList`（变量名/值/类型列表）

### 代码节点族

| type | tag | 中文名 | 语言/类型 | 输出 |
|------|-----|--------|----------|------|
| `codeNode` | `Code` | 执行代码 | `python3` | `result`(string) |
| `codeJythonNode` | `JythonNode` | Jython | `jython` | `outputList` |
| `codeGroovyNode` | `GroovyNode` | Groovy | `groovy` | `outputList` |
| `codeMagicNode` | `GroovyMagicTask` | Groovy 魔法指令 | groovy | `outputList` |
| `magicCodeNode` | `MagicCode` | Python 魔法指令 | `python3` | `outputList` |
| `executeCommandNode` | `ExecuteCommandNode` | 执行命令 | `json` | `outputList` |
| `codeCmdNode` | `CMDExecuteTask` | CMD | shell | `exitCode`, `out` |
| `codeShellNode` | `ShellExecuteTask` | Shell | shell | `result` |

**通用必填**：`script` 或 `codeContent`（视节点类型）

**magicCodeNode 额外字段**：`composerDoc`、`sessionId`、`agentId`、`status`

### httpNode — HTTP 请求

| type | tag |
|------|-----|
| `httpNode` | `Http` |

```json
{
  "title": "HTTP请求",
  "methodName": "get",
  "timeout": 5000,
  "outputList": [
    { "name": "body", "type": "string" },
    { "name": "statusCode", "type": "integer" },
    { "name": "headers", "type": "object" }
  ]
}
```

- **必填**：`url`
- **可选**：`methodName`、`headers`、`inputBodyType`

### 消息节点族

| type | tag | 中文名 | 协议 | 关键字段 |
|------|-----|--------|------|---------|
| `messageNode` | `Message` | 发送消息-SSE | SSE | `message`, `stream`, `messageType` |
| `dynamicMessageNode` | `DynamicMessage` | 发送动态消息 | WebSocket | `messageContent`, `messageId`（必填） |
| `businessMessageNode` | `SendBusinessMessage` | 发送业务消息 | WebSocket | `messageContent`（必填） |

**messageNode 输出**：`Answer_Content`、`status`

### textProcessingNode — 文本处理

| type | tag | 输出 |
|------|-----|------|
| `textProcessingNode` | `TextProcess` | `output`(string) |

```json
{
  "title": "文本处理",
  "processType": "concatenation",
  "template": "",
  "delimiter": "，"
}
```

- **processType**：`concatenation`（拼接）、`split`（分割）等

### toolNode — 组件/技能

| type | tag |
|------|-----|
| `toolNode` | `Skill` |

- **必填**：`skillId`
- **内置输出**：`statusCode`(number)、`body`(object)

### workflowNode — 工作流

| type | tag |
|------|-----|
| `workflowNode` | `WorkFlow` |

- **关键字段**：`workflowId`、`inputList`、`outputList`

### privateWorkflowNode — 私有工作流

| type | tag |
|------|-----|
| `privateWorkflowNode` | `PrivateWorkFlow` |

- **必填**：`workflowId`

### saveFileNode — 内容保存为文件

| type | tag |
|------|-----|
| `saveFileNode` | `FileSaver` |

```json
{
  "title": "内容保存为文件",
  "fileName": "",
  "input_Str": "",
  "type": ".md",
  "outputList": [
    { "name": "content_url", "type": "String" },
    { "name": "status", "type": "Boolean" },
    { "name": "file_type", "type": "String" }
  ]
}
```

- **必填**：`fileName`、`input_Str`、`type`

### syApiNode — SY 平台接口

| type | tag |
|------|-----|
| `syApiNode` | `SYPlatformServiceInvokeTask` |

- **必填**：`invokeType`、`serviceId`、`methodName`
- **输出**：`code`、`data`、`msg`

### xbotCommand — Xbot 指令

| type | tag |
|------|-----|
| `xbotCommand` | 运行时由 skill 决定 |

- **关键字段**：`skillId`、`formData`、`type`（WEB/MOBILE）
- **使用**：RPA Xbot 桌面/移动端指令封装

---

## 逻辑类

### ifNode / elseNode / elseifNode — 条件分支

| type | tag | 容器 |
|------|-----|------|
| `ifNode` | `if` | **是** |
| `elseNode` | `else` | **是** |
| `elseifNode` | `elseif` | **是** |

```json
{ "title": "IF", "logicalOperator": "and" }
```

- **关键字段**：`conditions`（条件数组）、`logicalOperator`（and/or）
- **高级**：`enableCustomLogic`、`customLogicExpression`
- **使用**：通常 IF → ElseIf* → Else 组合
- **JSON 层级**：`ifNode` 与 `elseNode` / `elseifNode` 为**同级兄弟**；`elseNode` **禁止**嵌在 `ifNode.content` 内
- **通用流程**：各分支汇合后共享的步骤 → 放在分支块**最外层之后**（composite plan 的 `postSteps`），**禁止**在每个分支内重复。见 [composite-workflow.md](composite-workflow.md)

### forNode — 列表循环

| type | tag | 容器 |
|------|-----|------|
| `forNode` | `for` | **是** |

```json
{ "title": "列表循环", "logicalOperator": "and", "loopType": "array" }
```

| loopType | 必填字段 |
|----------|---------|
| `array` | `list`（数组变量） |
| `increment` | `begin`、`end`、`step` |

- **循环变量**：`param`（默认 item 名）
- **控制**：`keepgoing`（出错继续）

### whileNode — While 循环

| type | tag | 容器 |
|------|-----|------|
| `whileNode` | `while` | **是** |

```json
{
  "title": "WHILE",
  "doWhile": false,
  "logicalOperator": "and",
  "maxLoopTimes": 20
}
```

- **关键字段**：`conditions`、`maxLoopTimes`、`doWhile`（先执行后判断）

### parallelNode — 并行分支

| type | tag | 容器 |
|------|-----|------|
| `parallelNode` | `parallelBranches` | **是** — `parallelBranchNode` |

- **子节点**：每个分支为 `parallelBranchNode`

### tryCatchNode — 错误处理

| type | tag | 容器 |
|------|-----|------|
| `tryCatchNode` | `TryCatchTask` | **是** — `tryNode|catchNode|finallyNode` |

- **结构**：Try → Catch → Finally（Finally 可选但推荐）
- **创建**：通过 `LocalBuiltInNodeMap` 工厂方法生成子节点

### noArgLeafNode — Break / Continue / Return

| type | tag（运行时） | 用途 |
|------|--------------|------|
| `noArgLeafNode` | `Break` | 跳出循环 |
| `noArgLeafNode` | `Continue` | 跳过当前迭代 |
| `noArgLeafNode` | `Return` | 终止整个工作流 |

```json
{
  "title": "Break",
  "description": "用于跳出循环",
  "enableThinkProcess": false
}
```

### agentIterator — 智能体循环

| type | tag | 容器 |
|------|-----|------|
| `AgentIterator` | `AgentIterator` | 否 |

```json
{
  "title": "智能体循环",
  "maxIterations": 5,
  "goalType": "NATURAL_LANGUAGE"
}
```

- **必填**：`query`、`agentId`、`agentType`、`maxIterations`
- **输出**：
  - `result.answer`(string)、`result.files`(array)
  - `goal_met`(boolean)
  - `iterations`(number)
  - `terminated_by`（`task_done` / `max_iterations` / `error`）

---

## RPA 指令

### rpaNode — 通用 RPA 原子指令

| 字段 | 值 |
|------|-----|
| type | `rpaNode` |
| tag | 运行时 = `unionId`（如 `OpenUrl`） |
| 容器 | 否 |
| 自动生成 | **白名单内 unionId 支持** |

**完整 attrs 示例**：

```json
{
  "type": "rpaNode",
  "attrs": {
    "tag": "OpenUrl",
    "nodeId": "abc123...",
    "nodeConfigState": "done",
    "disabled": false,
    "breakpoints": false,
    "actionType": "",
    "data": {
      "skillName": "打开网页(web)",
      "unionId": "OpenUrl",
      "id": 1,
      "commandType": 1,
      "showDesc": "打开网页 url:${url}",
      "toolDesc": "打开网页 url:https://example.com",
      "title": "打开网页(web)",
      "formData": {
        "url": "https://example.com",
        "browserType": "CHROME",
        "failOptions": { "failureHandling": "stop" },
        "sendMsgFlag": true,
        "toolDesc": "打开网页 url:https://example.com"
      }
    }
  }
}
```

**data 关键字段**：

| 字段 | 说明 |
|------|------|
| `unionId` | API 指令唯一标识，构建核心字段 |
| `id` | commandId，从 API 列表获取 |
| `skillName` / `title` | 指令中文名 |
| `showDesc` | 描述模板（含 `${selectorId}` 等占位符） |
| `formData` | 指令参数，结构因 unionId 而异 |
| `commandType` | 1 = Web 原子指令 |

**元素定位**（不入库 LLM 形式）：见 `node-schema.md` 与 `scripts/lib/build-nodes.mjs` → `buildSelectorId()`。

**本技能支持的 unionId（ALLOWED_UNION_IDS）**：

| 分类 | unionId |
|------|---------|
| 导航 | `OpenUrl`, `NavigateToUrl`, `BackPage`, `ForwardPage`, `ReloadPage` |
| 交互 | `FillText`, `ClickElementMixed`, `SendKeys`, `ScrollToElement`, `MouseOver` |
| 获取 | `GetText`, `GetUrl`, `GetWindowTitle`, `GetWindowIndex`, `TakeScreenshot` |
| 验证 | `VerifyElementPresent`, `VerifyElementVisible`, `VerifyElementNotPresent`, `VerifyElementNotVisible`, `VerifyTextPresent`, `VerifyTextNotPresent` |
| 等待 | `WaitForElementPresent`, `WaitForElementNotPresent`, `WaitPageState` |
| 其他 | `Delay` |

**formData 构建规则**：见 `reference/form-data-rules.md` 与 `scripts/lib/build-nodes.mjs` → `buildFormData()`。

**输出变量**：由 API `xbotJson.output` 定义；常见 `outKey`（如截图 `screenshotPath`）。

---

## 特殊 RPA 节点

### loopElementNode — 循环元素

| 字段 | 值 |
|------|-----|
| type | `loopElementNode` |
| tag | `LoopElements` |
| 容器 | **是** |
| 自动生成 | **否**（一期明确排除） |

```json
{
  "title": "循环元素",
  "commandId": 1209,
  "selectorId": "",
  "timeout": 0,
  "maxLoopTimes": 0,
  "reverse": false,
  "loadmore": "NO",
  "loopVariables": [
    { "name": "element", "type": "any" },
    { "name": "index", "type": "number" }
  ],
  "failOptions": { "failureHandling": "stop" }
}
```

- **关键字段**：`selectorId`、`timeout`、`maxLoopTimes`、`reverse`、`loadMoreAction`
- **使用**：对页面元素列表迭代，内部嵌套 RPA 指令

### assertNode — 断言

| 字段 | 值 |
|------|-----|
| type | `assertNode` |
| tag | `Assert` |
| 容器 | **是** |
| 自动生成 | 否 |

```json
{
  "title": "断言指令",
  "commandId": 1253,
  "failOptions": { "failureHandling": "stop" },
  "formData": {
    "assertFailCondition": "EXISTS_FALSE",
    "message": ""
  }
}
```

- **formData**：`assertFailCondition`（如 `EXISTS_FALSE`）、`message`
- **使用**：RPA 流程条件断言，失败时按 `failOptions` 处理

### rpaBlockNode — RPA Block

| 字段 | 值 |
|------|-----|
| type | `rpaBlockNode` |
| tag | `RpaBlock` |
| 容器 | **是** |
| 自动生成 | 否 |

```json
{
  "title": "RPA Block 指令",
  "id": 0,
  "commandType": 1,
  "formData": {}
}
```

- **使用**：将一组 RPA 指令打包为可复用 Block
- **id**：从拖拽指令或 API 动态获取

---

## 附录

### A. NodeType ↔ NodeTag 完整映射

| NodeType (type) | NodeTag (tag) |
|-----------------|---------------|
| `startNode` | `Start` |
| `endNode` | `End` |
| `triggerNode` | `TriggerTask` |
| `returnSubNode` | `ReturnSub` |
| `llmNode` | `LLM` |
| `kbNode` | `KnowledgeBase` |
| `updateKbNode` | `KnowledgeBaseUpdateTask` |
| `uiKbNode` | `ElementLibraryTask` |
| `parameterExtractorNode` | `ParameterExtractor` |
| `intentClassifierNode` | `IntentClassify` |
| `qaNode` | `QuestionAnswer` |
| `AITask-1` | `AITask-1` |
| `mcpNode` | `MCPTask` |
| `longTermMemorySearchTaskNode` | `LongtermMemorySearchTask` |
| `dateProcessNode` | `DateProcess` |
| `createDatasetsNode` | `CreateNewKbDatasetComponentTask` |
| `dataAnalysisNode` | `TemplateSourceLoaderComponentTask` |
| `faqSegmentNode` | `TemplateFAQLlmSplitterComponentTask` |
| `faqTemplateSegmentNode` | `TemplateFAQFormatSplitterComponentTask` |
| `segmentStorageNode` | `TemplateDataNodePersistComponentTask` |
| `textEmbeddingNode` | `TemplateEmbeddedComponentTask` |
| `textSegmentNode` | `TemplateCommonSplitterComponentTask` |
| `variableNode` | `DeclareVariable` |
| `codeNode` | `Code` |
| `codeJythonNode` | `JythonNode` |
| `codeGroovyNode` | `GroovyNode` |
| `codeMagicNode` | `GroovyMagicTask` |
| `magicCodeNode` | `MagicCode` |
| `executeCommandNode` | `ExecuteCommandNode` |
| `codeCmdNode` | `CMDExecuteTask` |
| `codeShellNode` | `ShellExecuteTask` |
| `httpNode` | `Http` |
| `messageNode` | `Message` |
| `dynamicMessageNode` | `DynamicMessage` |
| `businessMessageNode` | `SendBusinessMessage` |
| `textProcessingNode` | `TextProcess` |
| `toolNode` | `Skill` |
| `workflowNode` | `WorkFlow` |
| `privateWorkflowNode` | `PrivateWorkFlow` |
| `saveFileNode` | `FileSaver` |
| `syApiNode` | `SYPlatformServiceInvokeTask` |
| `xbotCommand` | （动态） |
| `ifNode` | `if` |
| `elseNode` | `else` |
| `elseifNode` | `elseif` |
| `forNode` | `for` |
| `whileNode` | `while` |
| `parallelNode` | `parallelBranches` |
| `tryCatchNode` | `TryCatchTask` |
| `noArgLeafNode` | `Break` / `Continue` / `Return` |
| `AgentIterator` | `AgentIterator` |
| `rpaNode` | unionId（如 `OpenUrl`） |
| `loopElementNode` | `LoopElements` |
| `assertNode` | `Assert` |
| `rpaBlockNode` | `RpaBlock` |

### B. 容器节点汇总（13 个）

`AITask-1`、`tryCatchNode`、`parallelNode`、`intentClassifierNode`、`qaNode`、`ifNode`、`elseNode`、`elseifNode`、`forNode`、`whileNode`、`loopElementNode`、`assertNode`、`rpaBlockNode`

### C. 子节点（无独立 node.ts 目录，由父节点 content 约束）

| type | 父节点 |
|------|--------|
| `classificationNode` | `intentClassifierNode` |
| `otherNode` | `intentClassifierNode`、`qaNode` |
| `parallelBranchNode` | `parallelNode` |
| `tryNode` | `tryCatchNode` |
| `catchNode` | `tryCatchNode` |
| `finallyNode` | `tryCatchNode` |

### D. 自动生成支持矩阵

| 节点 | 本技能自动生成 |
|------|---------------|
| `rpaNode`（unionId ∈ ALLOWED_UNION_IDS） | ✅ |
| `rpaNode`（其他 unionId） | ❌ |
| `loopElementNode` | ❌ |
| `assertNode` | ❌ |
| `rpaBlockNode` | ❌ |
| 所有非 rpaNode | ❌ |

### E. 源码路径索引

```
base-editor-v3/src/Editor/nodes/
├── agentIterator/    ai/              assert/
├── businessMessageNode/
├── code/{node,cmd,execute,groovy,jython,magic,magic-code,shell}/
├── dateProcess/      dynamicMessageNode/
├── else/             elseif/          endNode/
├── for/              http/            if/
├── intentClassifier/ kbNode/
├── kbNodes/{createDatasets,dataAnalysis,faqSegment,faqTemplateSegment,segmentStorage,textEmbedding,textSegment}/
├── llmNode/          longTermMemorySearchTask/
├── loop-element/     mcp/             messageNode/
├── noArgLeafNode/    parallelNode/    parameterExtractorNode/
├── privateWorkflow/  qa/              returnSub/
├── rpa/              rpaBlock/        saveFileNode/
├── startNode/        syApi/           textProcessingNode/
├── tool/             trigger/         triggerNodeForNocodb/
├── tryCatch/         uiKbNode/        updateKbNode/
├── variableNode/     while/           workflow/
└── xbotCommand/
```
