# Style Guide（P0 默认）

| Token | 值 | 用途 |
|-------|-----|------|
| paper | `#f5f5f0` | 背景 |
| paper-2 | `#ffffff` | 卡片 / 节点底 |
| ink | `#0a0a0a` | 主文字 |
| muted | `#6b7280` | 次要文字 |
| accent | `#eb6c36` | 焦点（最多 1–2 处） |
| hairline | `#d1d5db` | 1px 边框 |

## 字体

- Title / 标题：`Instrument Serif`, Georgia, serif
- Node name：`Geist`, system-ui, sans-serif
- Sublabel / 技术：`Geist Mono`, monospace

Google Fonts 链接（模板已含）：

```html
<link href="https://fonts.googleapis.com/css2?family=Instrument+Serif:ital@0;1&family=Geist+Mono:wght@400;500&display=swap" rel="stylesheet">
```

## 布局

- 所有坐标、宽高、间距尽量为 4 的倍数
- 最大 border-radius: 10px
- 无 box-shadow
- 1px hairline 边框

## 无障碍

SVG 必须：

```html
<svg role="img" aria-labelledby="diagram-title diagram-desc">
  <title id="diagram-title">…</title>
  <desc id="diagram-desc">…</desc>
```

ID 加 diagram 前缀避免同页冲突。
