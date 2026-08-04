# 验证元素具有属性

- **指令标识**：`MobileVerifyElementHasAttribute`
- **指令类型**：移动端指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/mobileverifyelementhasattribute/
- **说明**：验证手机当前屏幕中的特定UI元素具有选定的属性,输出验证结果（True或False）
- **必填输入参数**：`元素选择器`, `属性名称`
- **必填输出参数**：`将结果保存至`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 元素选择器 | String | 是 | - | 选择要验证的页面UI元素，可直接填写 xpath / 元素prompt 或从元素库选择 元素id |
| 属性名称 | String | 是 | - | 要验证的属性名称， eg：enabled、visible、clickable等 |
| 超时时间 | Double | 否 | 10000 | 查找元素超时退出时间 （ms，毫秒） |

## 输出参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 将结果保存至 | String | 是 | - | 输出指令的结果， False 表示元素不具有属性， True 表示元素具有属性 |

## XML 示例

```xml
<MobileVerifyElementHasAttribute    selector="//*[@text='团购']"    attributeName="name"    timeout="10000"    outKey="output"/>
```
