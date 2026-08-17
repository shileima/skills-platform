# Generic Type Fallback

当 `type-<slug>.md` 不存在时使用本规范。

1. 从 `types.md` 确认语义
2. 选最接近的已有布局（architecture / flowchart / tree / quadrant）
3. 保持 style-guide 配色与 4px 网格
4. 在回复中说明「使用 generic 布局近似 <slug>」

## 图表类（bar / line / scatter / gantt / radar）

- 用 SVG `<rect>` / `<polyline>` / `<circle>` 手绘，禁止 `<foreignObject>` 嵌 Chart.js
- 轴：hairline + muted 刻度标签
- 数据点 accent 高亮最大值或关键点

## 矩阵类（quadrant / dp-security-matrix）

- 四象限 divider cross hairline
- 象限标签 muted 小字在角
- 单元格内节点 paper-2 + border
