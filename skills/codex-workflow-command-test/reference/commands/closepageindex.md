# 关闭指定索引网页

- **指令标识**：`ClosePageIndex`
- **指令类型**：网页指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/closepageindex/
- **说明**：根据页面索引关闭浏览器中的指定页面，索引从0开始计算
- **必填输入参数**：`索引`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 索引 | Integer | 是 | - | 要关闭网页的索引，索引是一个从0开始的数字，索引在Chrome浏览器中按照网页打开顺序计算 |
| 超时时间 | Double | 否 | 2000 | 等待页面关闭的最大时长，超出则抛出异常，单位毫秒。默认 2000ms ，设置为 0 表示不等待 |

## XML 示例

```xml
<ClosePageIndex    index="0"    timeout="2000"/>
```
