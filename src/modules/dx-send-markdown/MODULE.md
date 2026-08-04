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

可选参数：

| 参数 | 说明 |
|------|------|
| `--all-tab` | 发送前点击「全部」Tab（`codex-dx-unread-messages` 从未读 Tab 返回时需要） |
| `--marker REGEX` | 写入 Markdown 编辑器后校验正文包含的关键词（默认：摘要首行非空） |

## 依赖

- 已安装并运行的 `cua-router-basic`（`daemon.sh start` + `exec.sh` 输出 `ok`）
- 大象桌面客户端已登录

## 流程

1. 打开并激活大象 App
2. 可选：点击「全部」Tab（`--all-tab`）
3. 在左侧搜索框输入接收人姓名过滤列表（**不要按 Enter**，否则会进入全局搜索页）
4. 点击过滤出的接收人单聊
5. 读取窗口宽度，`sky.click` 双击顶部居中 `(windowWidth/2, 6)` 放大窗口
6. 重新 `get_app_state({ disableDiff: true })`，在 AX Tree 中查找并点击「发送 Markdown 消息」
   - 若菜单未出现，降级：点击输入框前方 Markdown 按钮（`U+E124` / `U+E04D`）后再找菜单
7. 在浮层左侧「请输入内容」区域 `set_value` 写入正文
8. 点击右下角「发送」按钮并校验

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
