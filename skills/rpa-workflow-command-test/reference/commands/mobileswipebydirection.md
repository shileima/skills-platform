# 根据方向滑动屏幕

- **指令标识**：`MobileSwipeByDirection`
- **指令类型**：移动端指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/mobileswipebydirection/
- **说明**：在移动设备上按固定方向进行滑动操作
- **必填输入参数**：`slideDirection`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| slideDirection | String | 是 | DOWN | 方向枚举： UP LEFT RIGHT DOWN |
| slideSpeed | String | 否 | NORMAL | 滑动速度： FAST SLOW NORMAL |

## XML 示例

```xml
<MobileSwipeByDirection    slideDirection="DOWN"    slideSpeed="NORMAL"/>
```
