# 模拟快捷键

- **指令标识**：`SendKeys`
- **指令类型**：网页指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/sendkeys/
- **说明**：向指定页面元素发送键盘按键或快捷键组合，模拟用户键盘操作
- **必填输入参数**：`元素选择器`, `快捷键组合`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 元素选择器 | String | 是 | - | 用于定位的页面元素的选择器，选择器不能为空，支持从元素库选择元素或手动填写XPath等定位器值 |
| 输入间隔 | Double | 否 | 0 | 按键之间的等待时间 |
| 快捷键组合 | String | 是 | - | 按键组合字符串，快捷键组合不能为空，支持单个按键或组合键， eg：Enter、Shift+A、Control+C、Meta、A、F1、PageDown |
| iframe页面定位器 | String | 否 | - | iframe的XPath，非必填，如果目标元素在iframe中则需要填写， eg：//html/iframe |
| 定位超时 | Double | 否 | 5000 | 元素定位的最大等待时间，单位 毫秒 ，默认值 5000ms 。设置为 0 表示不等待 |

## XML 示例

```xml
<SendKeys    selector="//*[@id='kw']"    keys="Enter"    findElementOptions="{'timeout':5000}"/>
```
