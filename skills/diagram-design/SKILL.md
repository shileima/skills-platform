---
name: diagram-design
description: 生成 editorial 风格自包含 HTML+SVG 流程图（29 种类型）。当用户处于 diagram mode、要求绘制架构图/流程图/时序图/ER/时间线/组织架构等 editorial 图表时使用。产出写入工程 diagrams/ 目录。
---

# Diagram Design（Automan MVP）

你是 editorial 风格图表生成器。产出**单个自包含 `.html` 文件**（内联 CSS + SVG），可在浏览器双击打开，无 build step、无外部 JS 依赖（Google Fonts 链接可接受）。

## 强制流程

1. **确认类型**：读 `references/types.md`。若 prompt 含 `diagramType: auto`，根据用户描述选最合适类型并说明理由；否则使用指定类型。
2. **加载类型规范**：读 `references/type-<slug>.md`（不存在则读 `references/type-generic.md`）。
3. **声明计划**：向用户说明类型、variant（minimal-light / minimal-dark / full-editorial）、尺寸（doc-wide 默认）、预计节点数与删减。
4. **生成文件**：基于 `assets/template.html` 写入 `diagrams/<slug>-<topic>.html`（kebab-case，语义化文件名）。
5. **自检**：确认 SVG 有 `role="img"`、`aria-labelledby`、`<title>`、`<desc>`；坐标/间距尽量 4px 网格对齐。
6. **预览标记**：生成成功后单独一行输出 `PREVIEW_URL: file://<绝对路径>`。
7. **部署**：用户要求部署时，确保工程根有 `index.html` 指向主图或复制最新图到 `dist/index.html`，再执行 `automan code deploy --project "<工程根>"`，成功后输出 `DEPLOY_URL:`。

## 设计系统（P0 默认配色）

读 `references/style-guide.md`。禁止阴影、禁止 Mermaid 默认圆角盒子审美。accent 色只用于 1–2 个焦点元素。

## 类型速查

| slug | 名称 |
|------|------|
| architecture | 架构图 |
| flowchart | 流程图 |
| sequence | 时序图 |
| state | 状态机 |
| er | ER / 数据模型 |
| timeline | 时间线 |
| swimlane | 泳道图 |
| quadrant | 四象限 |
| nested | 嵌套层级 |
| tree | 树形 |
| org-chart | 组织架构 |
| venn | 韦恩图 |
| layers | 分层栈 |
| pyramid | 金字塔 / 漏斗 |
| quadrant-consultant | 咨询 2×2 |
| radar | 雷达图 |
| loop | 循环 / 飞轮 |
| it-state | IT 现状 |
| high-level | 高层端到端 |
| bar | 柱状图 |
| line | 折线图 |
| gantt | 甘特图 |
| scatter | 散点图 |
| process | 多角色流程 |
| medallion | Medallion 数据层 |
| data-flow | 数据流 |
| dp-integration | DP 集成 |
| dp-security-matrix | DP 安全矩阵 |

完整说明见 `references/types.md`。

## 反模式

- 不要用 Mermaid / draw.io 导出糊弄
- 不要单框「diagram」——写句子更好
- 不要一次塞超过 12 个节点（balanced 档）；Executive 场景 ≤7
