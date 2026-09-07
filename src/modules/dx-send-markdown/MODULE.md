# dx-send-markdown — 大象 Markdown 消息发送模块

通过 `cua-router-basic` / `sky.*` 将 Markdown 正文发送到大象桌面客户端 (`cn.neixin.pc`) 指定接收人的单聊会话。

## 用法

```bash
# 从技能 scripts 中调用（安装后模块在 <skill>/modules/dx-send-markdown/）
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
bash "$SKILL_DIR/modules/dx-send-markdown/scripts/send-markdown.sh" \
  "<接收人>" \
  --marker "摘要标题关键词" \
  < summary.md
```

接收人参数可省略。若省略，则按以下优先级解析，不再使用任何写死的默认值：

1. 读取本地 automan 客户端登录人：`~/Library/Preferences/automan/config.json` 的 `operator` 字段（可用 `AUTOMAN_CONFIG_FILE` 环境变量覆盖路径）；
2. 若仍为空，脚本输出 `{"ok":false,"error":"receiver_required",...}` 并以非零退出，由调用方（或 Agent）向用户询问「发送给谁」后再传入。

可选参数：

| 参数 | 说明 |
|------|------|
| `--all-tab` | 发送前点击「全部」Tab（`codex-dx-unread-messages` 从未读 Tab 返回时需要） |
| `--marker REGEX` | 写入 Markdown 编辑器后校验正文包含的关键词（默认：摘要首行非空） |

如需在其它脚本里复用同一套解析逻辑，可 `source` 模块的 `resolve-receiver.sh`：

```bash
source "$SKILL_DIR/modules/dx-send-markdown/scripts/resolve-receiver.sh"
RECEIVER="$(resolve_dx_receiver "${RECEIVER:-}")"
```

## 依赖

- 已安装并运行的 `cua-router-basic`（通过 `scripts/ensure-ready.sh` 探活）
- 脚本通过 `cua-router-basic/scripts/exec.sh -f` 在 `/exec` 隔离作用域中执行，直接使用运行时注入的 `sky.*` / `ax.*`
- 大象桌面客户端已登录

## 流程

1. 打开并激活大象 App
2. 可选：点击「全部」Tab（`--all-tab`）
3. 在左侧搜索框输入接收人姓名过滤列表（**不要按 Enter**，否则会进入全局搜索页）
4. **`waitForContactLine`**：粘贴后短暂等待并轮询 AX 树（最多 10 次）；`findContactLine` 仅精确匹配目标姓名（含嵌套 container），**不**降级点击第一个搜索结果
5. 点击过滤出的接收人单聊
6. **校验右侧会话顶栏**是否为目标接收人（`verifyRightPaneReceiver`；过滤窗口名「大象」等；不匹配则重试点击联系人，最多 3 次）
7. 从 `get_app_state` 截图尺寸计算坐标，`sky.click` 双击标题栏 `(width/2, height*0.02)` 放大窗口
8. 重新 `get_app_state({ disableDiff: true })`；**再次校验右侧会话**后，在 AX Tree 中查找并点击「发送 Markdown 消息」
   - 点击 Markdown 工具栏按钮、以及点击「发送 Markdown 消息」菜单项前，均会再次校验会话
   - 若菜单未出现，降级：点击输入框前方 Markdown 按钮（`U+E124` / `U+E04D`）后再找菜单
9. 在浮层左侧「请输入内容」区域 `set_value` 写入正文
10. 点击右下角「发送」按钮并校验

## 右侧会话校验

避免「搜索框仍显示姓名、但右侧实际停留在群聊/其它会话」时误发（例如发到「Automan客户端开发」群）：

- 从 AX 树中读取右侧顶栏标题行，须与 `receiver` **完全一致**
- 排除左侧搜索框区域（`searchIdx` 附近）内的同名文本，不再使用 `text.includes(receiver)` 作为会话判断
- 失败时返回 `active_conversation_mismatch`，并在 `hint` 中给出当前会话名，例如：`右侧当前会话为「XXX」，不是目标「马世磊」`

## 技能引用

在 `skill.json` 中声明：

```json
"modules": ["dx-send-markdown"]
```

构建/安装时会将本模块拷贝到技能包的 `modules/dx-send-markdown/`。

脚本内解析模块路径（开发态回退到仓库 `src/modules/`）：

```bash
source "$(dirname "$0")/resolve-module.sh"
MOD_ROOT="$(resolve_module_root "$SKILL_DIR" dx-send-markdown)"
bash "$MOD_ROOT/scripts/send-markdown.sh" "$@"
```
