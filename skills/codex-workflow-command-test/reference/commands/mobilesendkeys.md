# 输入文本

- **指令标识**：`MobileSendKeys`
- **指令类型**：移动端指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/mobilesendkeys/
- **说明**：在移动设备上向指定元素输入文本内容
- **必填输入参数**：`selector`, `keyword`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| selector | String | 是 | - | 选择要点击的页面UI元素，可直接填写 xpath/元素prompt 或从元素库选择 元素id |
| keyword | String | 是 | - | 需要输入的按键内容(支持中文、特殊符号) |
| timeout | Integer | 否 | 10000 | 最大等待时间 (ms) |

## XML 示例

```xml
<MobileSendKeys    selector="//*[@text='请输入手机号' and @resource-id='com.sankuai.meituan.takeoutnew:id/passport_mobile_phone']"    keyword="13800000000"    timeout="10"/>
```
