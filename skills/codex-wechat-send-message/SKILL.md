---
name: codex-wechat-send-message
description: >
  macOS 微信桌面客户端给指定联系人发送消息。快速稳定路径：cliclick 固定坐标 +
  剪贴板输入，全程零 OCR。文件传输助手 (0.18,0.28)，业务联系人从聊天列表 (0.18,0.21) 打开。
  当用户说「微信发消息给 X」「给 X 发微信说 Y」或类似意图时激活。
---

# codex-wechat-send-message — 微信发送消息

macOS 微信 (`com.tencent.xinWeChat`) 发文本消息。**固定坐标快速路径**，约 5–8 秒完成，详见 `references/stable-flow.md`。

## 依赖

- `cua-router-basic`：`ensure-ready`（仅启动时用，流程中不截图）
- `cliclick`：`brew install cliclick`

## 一键执行

```bash
bash "./scripts/send-message.sh" "<联系人>" "<消息>"
bash "./scripts/send-test-message.sh" ["<消息>"]   # → 文件传输助手
```

## 快速路径

| 场景 | 打开 | 发送 |
|------|------|------|
| 文件传输助手 | 列表 `(0.18, 0.28)` 双击 | 输入框粘贴 → `(0.88, 0.93)` |
| 业务联系人 | 列表 `(0.18, 0.21)` 双击 + 聚焦右侧 | 同上 |

**禁止**：侧栏搜索（误开搜一搜）、OCR 轮询、反复 fallback。

## 可调参数

- `WECHAT_CONTACT_LIST_Y=0.21` — 联系人在最近聊天列表的行位置
- `WECHAT_VERIFY=1` — 启用发送后 OCR 校验（变慢）

## Agent 指引

1. 直接跑 `send-message.sh` / `send-test-message.sh`
2. stdout 最后一行 JSON，`ok:true` 即成功
3. 不要逐步 `inspect/act`
