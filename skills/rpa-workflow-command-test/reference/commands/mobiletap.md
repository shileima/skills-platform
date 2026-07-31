# 点击

- **指令标识**：`MobileTap`
- **指令类型**：移动端指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/mobiletap/
- **说明**：在移动设备上点击指定页面元素
- **必填输入参数**：`selector`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| selector | String | 是 | - | 选择要点击的页面UI元素，可直接填写 xpath / 元素prompt 或从元素库选择 元素id |
| timeout | Integer | 否 | 10000 | 查找元素超时退出时间（ ms ） |

## XML 示例

```xml
<MobileTap    selector="//*[@text='登录']"    timeout="10"/>
```
