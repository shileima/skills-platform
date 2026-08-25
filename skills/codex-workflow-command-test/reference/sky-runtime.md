# Sky 运行时（速度 + 准确率 · 每次执行必读）

> **定位**：本模块是**所有 `/exec` sky 步骤的共享运行时**——helper 维护在 `scripts/workflow-runtime.mjs`，插入/配表/调试模块引用本文件，禁止各模块各自复制变体。
>
> **调用方**：`insert-command.md`、`platform-ops.md`、`test-workflow.md`、`element-selector.md`、`url-input.md`、`debug.md`。
>
> **传输层**：`cua-router-basic/scripts/exec.sh -f` 调用 `/exec`，在隔离作用域中使用自动注入的 `sky.*` / `ax.*`。业务脚本必须从文件执行，禁止拼接超长内联 JavaScript。
>
> **目标**：更少步骤往返、更短等待、更高 idx 命中率、更少 canvas 污染。

## 标准执行入口

每个 sky 步骤批次：

```bash
SKILL_DIR="${WORKFLOW_SKILL_DIR:-$HOME/.cursor/skills/codex-workflow-command-test}"

# Shell 前置（URL / LLM 描述 / XPath）：必须在 `/exec` 步骤前执行
printf '%s' 'https://www.bilibili.com' | /usr/bin/pbcopy

# 运行一步（helper 与 sky 已自动注入）
bash "$SKILL_DIR/scripts/run-workflow-hosted.sh" <<'JS'
await sky.get_app_state({ app, disableDiff: true });
emitResult({ step: "runtime-ready", app });
JS
```

`-f` 运行完整脚本（脚本内自行 `import` workflow-runtime）：

```bash
bash "$SKILL_DIR/scripts/run-workflow-hosted.sh" -f "$SKILL_DIR/scripts/bilibili-four-step.mjs"
```

## 执行前：Chrome 前台

> 🚫 **禁止**在 `cgWindowNotFound` 时盲目 `daemon.sh restart`——优先走本节；仅当 `ensure-ready.sh` 也失败时才 restart。

`run-workflow-hosted.sh` 默认会调用 `scripts/lib/ensure-chrome-front.sh`。手动恢复：

```bash
bash "$SKILL_DIR/scripts/lib/ensure-chrome-front.sh"
```

**工作流页已存在时**（失焦恢复 · 禁止用地址栏导航离开当前 Tab 再回来）：

```bash
WORKFLOW_URL="https://rpa.sankuai.com/space/<spaceId>/workflow/<workflowId>/config?subType=2"
osascript -e "tell application \"Google Chrome\" to activate" \
  -e "tell application \"Google Chrome\" to set URL of active tab of front window to \"$WORKFLOW_URL\""
sleep 5
bash "$SKILL_DIR/scripts/lib/ensure-chrome-front.sh"
```

每个 `/exec` 步骤**第一行必须是** `await sky.get_app_state({ app, disableDiff: true })`（满足 Computer Use 激活要求）。

## 步骤批次策略（速度）

| 策略 | ✅ 推荐 | ❌ 禁止 |
|------|--------|--------|
| 批次粒度 | **一条指令 = 一次 `/exec` 步骤**：`insert → 配表 → 保存 → canvas 验证` | 每条指令拆成 5+ 次步骤 |
| 全场景 | 4 步场景 ≤ **6 次步骤**（前置 1 + 每指令 1 + 终检**+一次性调试** 1） | 每指令步骤后点「调试」；配置未完成就运行 |
| 等待 | **轮询 AX**（350ms × ≤6） | 固定 `sleep(2000)` 盲等 |
| 「检查」 | **全部指令保存后** 点一次 | 每保存一条都点「检查」 |
| 「调试」 | **终检通过后** 一次性「调试 → 运行」 | **每条指令插入/保存后调试** |
| 剪贴板 | **Shell** `printf '%s' '…' \| pbcopy`，再进 hosted paste | 进程内 `execFileSync('pbcopy')` |
| 导航 | **钉在工作流 Tab**；XPath 采集用 **Cmd+T 新 Tab** | 工作流 Tab 地址栏打开目标站（丢 canvas） |
| idx | **同步骤内**动态解析；下一步骤重新抓树 | 跨步骤复用 `element_index` |
| 失败 | 同指令 **2 次**仍失败 → 删节点原位重插 | 同位置连点 4+ 次 |

## 共享 Helper（`scripts/workflow-runtime.mjs`）

以下 helper 在 `run-workflow-hosted.sh` 内**自动注入**，无需复制：

| Helper | 用途 |
|--------|------|
| `sky`, `app`, `sleep`, `emitResult` | 基础 |
| `findIdx` / `findAllIdx` / `linesOf` | AX 行解析 |
| `axHasLabel` / `axButtonIdx` | AntD 按钮标签 |
| `findCmdTab` / `findSearchIdx` / `waitSearchIdx` | 指令 Tab + 搜索框 |
| `defocusCanvas` | 编排区 Tab + Escape（**禁止**点「调试」失焦） |
| `findCanvasNode` / `listCanvasNodes` | canvas 节点摘要 |
| `dblclickWebResult` / `dblclickWebResultLoose` | 双击搜索结果 |
| `insertAfterAnchor` | 锚点 → Enter → 搜索 → 双击 |
| `configLLMScoped` / `fillAsciiField` / `saveDialog` | 弹框配表 |
| `reorderNodeCutPaste` / `fixClickNodeLLM` | 调序 / 修复 selectorId |
| `debugRunOnce` | 终检后唯一一次调试 |
| `assertCanSave` / `assertCanSaveOpenUrl` | 保存前门控 |

维护者扩展 helper 时只改 `scripts/workflow-runtime.mjs`。

## 单条 Web 指令标准步骤模板

> **Shell 前置**（URL / LLM 描述 / XPath）：`printf '%s' '…' | /usr/bin/pbcopy`

```bash
bash "$SKILL_DIR/scripts/run-workflow-hosted.sh" <<'JS'
await sky.get_app_state({ app, disableDiff: true });

const { aIdx, rIdx } = await insertAfterAnchor(
  "打开网页",
  "输入文本",
  /text\s+输入文本\s*\(web\)/
);

await configLLMScoped();
await fillAsciiField(/text\s+\*\s+待填充文本/, "bilibili");
await saveDialog();

const s = await sky.get_app_state({ app, disableDiff: true });
const onCanvas = /元素中输入 bilibili|输入文本/.test(s.text);
emitResult({ step: "filltext-done", aIdx, rIdx, onCanvas, strategy: "ax:insert+llm+type" });
JS
```

## 等待时间表（优化后）

| 动作 | 等待 | 验证 |
|------|------|------|
| canvas 单击 / Enter | 300–400ms | 锚点/空行仍在 |
| 指令 Tab + 搜索框 | `waitSearchIdx()` | `请输入` 出现 |
| set_value 搜索词 | 500–800ms | 网页自动化分组下出现结果行 |
| 双击搜索结果 | 1200ms | 配置弹框信号；「刷新网页」可无 `(web)` 后缀 |
| 剪切调序 Cmd+X/V | 500–800ms | canvas 顺序符合场景表 |
| LLM 确认 | 800ms | 选择器 slice 含 `LLM` |
| ASCII 待填充文本 | `type_text` + 300ms | slice 含目标文本 |
| 保存 | 1500ms | 弹框关闭 / canvas 摘要更新 |
| 页面导航（仅平台入口） | 2000ms | URL 含目标路径 |

## 准确率铁律

1. **保存前**：弹框 slice 必含已填值；`canSave === false` 禁止点保存（`ax-verify.md` §assertCanSave）。
2. **保存后**：读 canvas 节点摘要行（如 `打开网页 url:`、`元素中输入 bilibili`），**不对**则当场重开弹框，禁止继续插下一条。
3. **LLM「确认」**：只用 `configLLMScoped` slice 内按钮；全局 `确 认`（如 idx 61）会误关其他弹层。
4. **顺序**：插入后 canvas 序列必须 `锚点 < 新节点 < 结束`；错乱 → 剪切粘贴（`insert-command.md` §右键菜单），**禁止**带错顺序继续配表。
5. **canvas 污染**：同指令失败 2 次 → **Delete 错节点** 或 **新建工作流**，不要在脏 canvas 上堆节点。
6. **禁止用「调试」失焦**：`defocusCanvas` 只点「编排区」+ Escape；点「调试」会开面板并在聊天区留失败日志。
7. **聊天区历史**：早先误调试的失败条目会残留；判 PASS 只看**最新一轮**各步骤 `check-circle` 与时间戳。

## B 站四步黄金路径（实测 · 2026-08-22）

> 默认场景完整参数见 `scenarios/bilibili.md` §实测黄金路径。配置阶段**零次**点「调试」。
>
> 一键调试：`bash scripts/debug-run-once.sh`（终检通过后唯一允许点「调试」时使用）。

| Step # | Shell 前置 pbcopy | 动作 | canvas 摘要验证 |
|--------|-------------------|------|----------------|
| 1 | `https://www.bilibili.com` | 开始 → 插入「打开网页」→ 弹框 paste 网址 → 保存 | `打开网页 url: https://www.bilibili.com` |
| 2 | 搜索框 LLM 描述 | 锚点 `bilibili.com` → 插入「输入文本」→ LLM + `type_text bilibili` → 保存 | `元素中输入 bilibili` |
| 3 | 搜索按钮 LLM 描述 | 锚点 `元素中输入 bilibili` → 插入「点击」→ LLM → 保存 | `点击 页面`（非 `selectorId`） |
| 4 | — | 锚点 `点击 页面` → 搜「刷新网页」→ `dblclickWebResultLoose("刷新网页")` → 保存 | `刷新网页` |
| 5 | — | 顺序终检 + 点一次「检查」 | 无「节点配置不完整」 |
| 6 | — | **唯一一次**「调试 → 运行」→ 等 `check-circle` | 4 步均 ✅ |

**platformRe 参考**：

| 指令 | 搜索框 | dblclick 匹配 |
|------|--------|--------------|
| 打开网页 | `打开网页` | `/text\s+打开网页\s*\(web\)/` |
| 输入文本 | `输入文本` | `/text\s+输入文本\s*\(web\)/` |
| 点击 | `点击` | `/点击\s*\(web\)\|点击元素\s*\(web\)/` |
| 刷新网页 | `刷新网页` | **`dblclickWebResultLoose("刷新网页")`**（无 `(web)`） |

## 一次性调试（终检后唯一允许点「调试」）

```bash
bash "$SKILL_DIR/scripts/run-workflow-hosted.sh" <<'JS'
await sky.get_app_state({ app, disableDiff: true });
const result = await debugRunOnce();
emitResult(result);
JS
```

## cgWindowNotFound 恢复顺序

```
1. bash scripts/lib/ensure-chrome-front.sh
2. 若仍失败：AppleScript 设工作流 URL + sleep 5
3. 若仍失败：daemon.sh stop && daemon.sh start → bash scripts/ensure-ready.sh
4. 禁止在未恢复时连发多个 `/exec` 步骤
```

详见 `debug.md` §Chrome 报 cgWindowNotFound。

## 与其他模块关系

| 模块 | 使用本运行时 |
|------|-------------|
| `insert-command.md` | `waitSearchIdx` / `insertAfterAnchor` / `dblclickWebResult` |
| `element-selector.md` | `configLLMScoped` |
| `url-input.md` | Shell pbcopy + scoped paste |
| `test-workflow.md` | 步骤批次策略、延迟「检查」、一次性调试 |
| `debug.md` | `debugRunOnce`、断开重试、聊天区历史判读 |
| `platform-ops.md` | 新建工作流 sky 步骤、defocusCanvas |

## 依赖声明

参照 `cua-router-basic` 的 `references/install.md` 与 `references/runtime-exec.md`；确定性脚本通过 `exec.sh -f` 执行。
