# 获取元素属性

- **指令标识**：`GetElementAttribute`
- **指令类型**：网页指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/getelementattribute/
- **说明**：获取指定页面元素的HTML属性值，支持所有标准HTML属性的获取
- **必填输入参数**：`元素选择器`, `属性名称`
- **必填输出参数**：`将结果保存至`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 元素选择器 | String | 是 | - | 用于定位的页面元素的选择器，选择器不能为空，支持从元素库选择元素或手动填写XPath等定位器值 |
| 属性名称 | String | 是 | - | 要获取的HTML元素属性名称，属性名称不能为空，常见属性包括 class 、 id 、 value 、 href 、 title 、 src 等，例如： class 、 value |
| iframe页面定位器 | String | 否 | - | iframe的XPath，非必填，如果目标元素在iframe中则需要填写，例如： //html/iframe |
| 定位超时 | Double | 否 | 5000 | 元素定位的最大等待时间，单位毫秒，默认值 5000ms 。设置为 0 表示不等待 |

## 输出参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 将结果保存至 | String | 是 | - | 填写变量名称（例如：attributeValue），保存获取到的元素属性值，返回字符串类型 |

## XML 示例

```xml
<GetElementAttribute  selector="//*[@id='__next']/div[2]/div[2]/section/div[1]/h1"  attributeName="class"  findElementOptions="{'timeout':5000}"  outKey="output"/>
```

## 注意事项

- href：链接地址
- src：资源地址（图片、脚本等）
- value：输入框的值
- class：CSS类名
- id：元素ID
