# 验证文本存在

- **指令标识**：`VerifyTextPresent`
- **指令类型**：网页指令（"网页自动化 → 网页断言"分组）
- **平台指令名**：`验证文本存在`（**不含 `(web)` 后缀**）
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/verifytextpresent/
- **说明**：验证指定文本是否出现在当前页面 DOM/可见文本中
- **必填输入参数**：`待验证文本`
- **必填输出参数**：`将结果保存至`（默认为节点 ID）

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 待验证文本 | String | 是 | - | 页面中需要验证存在的文本内容 |
| 是否为正则表达式 | Boolean | 否 | false | 是否将"待验证文本"作为正则匹配 |
| 定位超时 | Double | 否 | 5000 | 等待文本出现的最大时间（毫秒） |

## 输出参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 将结果保存至 | String | 是 | 节点 ID | 保存验证结果（true / false） |

## 平台搜索/双击定位注意事项

在右侧「指令」Tab 搜索框输入 `验证文本存在` 后，AX Tree 上只会出现**一条**匹配项 `X 文本 验证文本存在`（**不是** `text 验证文本存在 (web)` 格式）。双击目标行：

```js
const target = lines.find(l => /^\s*\d+\s+文本\s+验证文本存在$/.test(l.trim()));
```

## 配置弹框字段（type_text 首选）

弹框内唯一必填字段 `* 待验证文本` 底层是 **"文本输入区 (settable, string)"**（Monaco/CodeMirror 类）：

| 输入方式 | 效果 | 建议 |
|---------|------|------|
| `set_value(idx, "text")` | AX Value 更新但 React state 常不生效 | ❌ 不推荐 |
| `press_key("Cmd+V")` + 中文剪贴板 | 部分情况下 IME 冲突失败 | 中文时需要 Chrome 前台稳定 |
| `type_text("baidu")`（**ASCII**） | 稳定可靠 | ✅ **推荐 ASCII** |

**推荐**：如果场景允许，用 ASCII 文本（如百度首页版权栏含 `Baidu`）；必须中文时先 `pbcopy` + `osascript` 强制 Chrome 前台 + `Cmd+V`。

## 常见踩坑

| 现象 | 原因 | 处理 |
|------|------|------|
| Cmd+V 中文粘贴 filled=false | 文本输入区 IME 冲突 | 改用 type_text ASCII；或替换测试文本 |
| set_value 无效 | Monaco 类编辑器不接受 AXValue 写入 | 换 type_text / Cmd+V |
| 断言失败 | 页面上真的没有该文本 | 用 DevTools 确认页面是否含该字符串 |
