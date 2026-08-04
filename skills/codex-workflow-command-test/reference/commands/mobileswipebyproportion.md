# 根据屏幕比例滑动

- **指令标识**：`MobileSwipeByProportion`
- **指令类型**：移动端指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/mobileswipebyproportion/
- **说明**：在移动设备上按屏幕比例进行滑动操作
- **必填输入参数**：`startX`, `startY`, `endX`, `endY`, `slideSpeed`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| startX | Double | 是 | - | 起点x轴比例，起始坐标x轴的比例，区间 0~1 |
| startY | Double | 是 | - | 起点y轴比例，起始坐标y轴的比例，区间 0~1 |
| endX | Double | 是 | - | 终点x轴比例，结束坐标x轴的比例，区间 0~1 |
| endY | Double | 是 | - | 终点y轴比例，结束坐标y轴的比例，区间 0~1 |
| slideSpeed | String | 是 | NORMAL | 滑动速度，屏幕滑动的速度选项（ FAST NORMAL SLOW ） |

## XML 示例

```xml
<MobileSwipeByProportion    startX="0.5"    startY="0.7"    endX="0.5"    endY="0.3"    slideSpeed="NORMAL"/>
```
