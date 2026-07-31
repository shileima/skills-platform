# 等待元素具有属性

- **指令标识**：`MobileWaitForElementHasAttribute`
- **指令类型**：移动端指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/mobilewaitforelementhasattribute/
- **说明**：等待手机当前屏幕中的特定UI元素具有属性值，返回结果（True或False），成功后继续执行
- **必填输入参数**：`元素选择器`, `属性名称`
- **必填输出参数**：`将结果保存至`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 元素选择器 | String | 是 | - | 元素定位方式， eg：xpath |
| 属性名称 | String | 是 | - | 要验证的属性名称 |
| 超时时间 | Double | 否 | 10000 | 查找元素超时时间 （ms，毫秒） |

## 输出参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 将结果保存至 | String | 是 | - | 输出指令的结果， True / False |

## XML 示例

```xml
<MobileWaitForElementHasAttribute    selector="//*[@content-desc='我的']"    attributeName="clickable"    timeout="10000"    outKey="output"/>
```
