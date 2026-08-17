# 29 种图表类型选型

## 自动推荐（diagramType: auto）

按用户意图匹配：

| 用户描述关键词 | 推荐 slug |
|----------------|-----------|
| 架构、组件、服务、系统 | architecture |
| 决策、分支、if/else、审批 | flowchart |
| 调用顺序、API、消息、交互 | sequence |
| 状态、生命周期、流转 | state |
| 表结构、实体、字段、数据库 | er |
| 里程碑、年份、事件轴 | timeline |
| 跨部门、角色、泳道 | swimlane |
| 优先级、象限、impact/effort | quadrant |
| 层级、包含、嵌套 | nested |
| 父子、分类树 | tree |
| 组织、汇报线、团队 | org-chart |
| 交集、重叠集合 | venn |
| 分层、协议栈 | layers |
| 优先级金字塔、漏斗 | pyramid |
| 2×2 矩阵、战略 | quadrant-consultant |
| 多维对比、能力雷达 | radar |
| 飞轮、循环增强 | loop |
| 遗留系统、现状 IT | it-state |
| 端到端、高层概览 | high-level |
| 柱状、分类对比 | bar |
| 趋势、折线 | line |
| 排期、阶段、甘特 | gantt |
| 分布、相关性 | scatter |
| 多角色协作流程 | process |
| 数据湖 bronze/silver/gold | medallion |
| 管道、ETL 数据流 | data-flow |
| 数据源集成 | dp-integration |
| 权限矩阵 | dp-security-matrix |

## 密度预算

| 档位 | 节点上限 |
|------|----------|
| simplified | 7 |
| balanced | 12 |
| faithful | 24 |

默认 balanced。

## 未单独建 type 文件的类型

读 `type-generic.md`，按最接近的视觉隐喻绘制（tree→nested，bar/line/scatter→quadrant 轴逻辑等）。
