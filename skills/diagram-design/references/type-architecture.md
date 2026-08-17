# Architecture

## 用途
组件 + 有向连接。展示系统边界、服务、存储。

## 布局
- 左→右或上→下数据流
- 矩形节点 + 箭头连线，边上可标协议/动作
- 外部系统用 dashed 边框

## 节点
- 标题 12–14px Geist 600
- 副标题 10px mono（端口、协议）

## 示例结构
Browser → API Gateway → Service → DB / Cache

## 反模式
- 不要对角线 spaghetti
- 不要每个节点不同颜色
