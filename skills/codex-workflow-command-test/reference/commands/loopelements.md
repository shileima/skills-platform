# 循环遍历元素（LoopElements）

- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/loopelements/
- **指令实现**：`rpa-engine-server/src/main/java/org/rpa/engine/task/pc/LoopElements.java`
- **平台搜索名称**：`循环遍历`（浮层输入后取「网页自动化 → 元素操作」分组下的 `循环遍历 元素`，注意中间有空格）
- **说明**：循环遍历页面中所有匹配选择器的元素，支持滚动加载、点击加载等多种方式动态加载更多元素；循环体内通过 `@{toolId.index}` 定位当前元素（index 从 1 开始）

## 参数

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| selector | String | ✅ | - | 元素选择器（XPath），匹配要循环的元素列表 |
| outputList | JSON | ✅ | - | 输出参数配置，收集每次循环的数据，格式 `[{"name":"字段名","value":"${循环内变量}"}]` |
| outKey | String | ❌ | toolId | 存储输出数据的变量名，默认与 toolId 相同 |
| maxLoopTimes | Integer | ❌ | 1000 | 最大循环次数（不得超过 1000） |
| timeout | Number | ❌ | 3000 | 等待元素出现时间（毫秒） |
| reverse | Boolean | ❌ | false | 是否倒序遍历 |
| loadMoreAction | Enum | ❌ | NONE | 加载更多操作：`NONE` / `CLICK_ELEMENT` / `SCROLL_DOWN` / `SCROLL_UP` |
| loadMoreSelector | String | 条件必填 | - | 加载更多按钮选择器（`loadMoreAction=CLICK_ELEMENT` 时必填） |
| scrollToBottom | Boolean | ❌ | false | 是否滚动到底部 |
| scrollToTop | Boolean | ❌ | false | 是否滚动到顶部 |
| loadMoreWaitTime | Number | ❌ | 3000 | 加载更多等待时间（毫秒） |
| keepgoing | Boolean | ❌ | false | 单次遍历出错时是否继续 |
| frameSelector | String | ❌ | - | iframe 选择器，元素在 iframe 中时使用 |

## 官方 XML DSL 示例

```xml
<LoopElements
  selector="//*[@class='item-list']/li"
  outputList='[{"name":"titles","value":"${title}"}]'
  toolId="loopResult"
  outKey="loopResult">

  <!-- 子指令：通过 @{toolId.index} 定位当前循环元素（index 从 1 开始）-->
  <GetText
    selector="//*[@class='item-list']/li[@{loopResult.index}]/h2"
    outKey="title"/>
</LoopElements>
```

## 输出结果

循环收集的数据（JSON 对象），字段名由 `outputList` 中的 `name` 决定，值为每次循环收集到的**数组**：

```json
{
  "titles": ["标题1", "标题2", "标题3"],
  "prices": ["¥99", "¥199", "¥299"]
}
```

**访问方式**（在循环节点**之后**的其他指令中）：

| 需求 | 表达式 |
|---|---|
| 单个字段（数组） | `${outKey.字段名}`，如 `${loopResult.titles}` |
| 数组长度 | `${outKey.字段名.size()}`，如 `${loopResult.titles.size()}` |
| 第 N 项 | `${outKey.字段名[N]}` |

## 循环体内变量

平台自动注入以下变量供循环体内子指令引用：

| 变量 | 类型 | 说明 |
|---|---|---|
| `@{toolId.index}` | number | 当前迭代索引，**从 1 开始**；子指令通过此变量拼接 XPath 定位当前元素 |

> ⚠️ 注意变量前缀是 **`@{}`** 不是 `${}`（`${}` 用于循环节点**外**访问 `outputList` 收集的数组）

## 关键约束

1. **必填参数只有 2 个**：`selector` + `outputList`
2. **`outputList` 的 `value` 只能引用循环内部指令的输出变量**，不能引用外部变量
3. **子指令必须用 `@{toolId.index}`** 定位当前循环元素——直接用固定 XPath 每次都拿同一个元素
4. **`maxLoopTimes` ≤ 1000**
5. **`CLICK_ELEMENT` 时 `loadMoreSelector` 必填**
6. 支持在循环体内使用 `Break` / `Continue` 指令
7. **`keepgoing=true`** 时单次元素失败不中断循环

## 常用循环体子指令组合

### A. 收集所有匹配元素的文本

```xml
<LoopElements selector="//a[@class='title']"
              outputList='[{"name":"titles","value":"${title}"}]'
              outKey="loopResult">
  <GetText selector="(//a[@class='title'])[@{loopResult.index}]" outKey="title"/>
</LoopElements>
```

调用后 `${loopResult.titles}` 是 N 条标题的数组。

### B. 收集多字段（标题 + 链接）

```xml
<LoopElements selector="//div[@class='note-item']"
              outputList='[{"name":"titles","value":"${title}"},{"name":"links","value":"${link}"}]'
              outKey="loopResult">
  <GetText selector="(//div[@class='note-item'])[@{loopResult.index}]//h2" outKey="title"/>
  <GetElementAttribute selector="(//div[@class='note-item'])[@{loopResult.index}]//a" attribute="href" outKey="link"/>
</LoopElements>
```

### C. 滚动加载更多

```xml
<LoopElements selector="//div[@class='feed-item']"
              outputList='[{"name":"texts","value":"${t}"}]'
              outKey="loopResult"
              loadMoreAction="SCROLL_DOWN"
              scrollToBottom="true"
              loadMoreWaitTime="2000"
              maxLoopTimes="100">
  <GetText selector="(//div[@class='feed-item'])[@{loopResult.index}]" outKey="t"/>
</LoopElements>
```

## 配置要点（rpa 编排 UI）

在弹框的 **[常规] Tab** 里配置：

1. **输入参数 → 元素选择器**：pbcopy + Cmd+V + Enter 填入 XPath（[element-selector.md §方式 C](../element-selector.md)）
2. **循环变量信息**（只读表格）：会自动显示 `index / number` 一行，说明可用 `@{toolId.index}` 引用
3. **输出参数**：点「+ 添加」新增一行，填「参数名称 / 参数类型（默认 `array<string>`）/ 参数值」
   - 参数名称 → `titles`（自定义）
   - 参数值 → `${title}`（引用循环体内 GetText 节点的 outKey）
4. **保存**

**循环体子节点**：单击循环节点行 → Enter → 循环节点内部出现"通过输入或者从指令列表拖拽添加指令"空槽 → 搜索并双击子指令即可嵌入

## 自动化配置示例

```bash
# Shell 侧：pbcopy 元素选择器
echo -n '//a[@class="title"]' | pbcopy
```

```js
// sky 侧：一次 exec 内完成"元素选择器 + outputList + 保存"（跨 exec 的 idx 会失效）
{
  const sleep = (ms) => new Promise(r => setTimeout(r, ms));
  // 1. 双击 canvas 里的循环节点
  const s = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  const loopNode = s.text.split("\n").find(l => /^\s+\d+\s+text\s+循环遍历元素/.test(l));
  const loopIdx = parseInt(loopNode.match(/^\s*(\d+)/)[1]);
  await sky.click({ app: "com.google.Chrome", element_index: loopIdx, click_count: 2 });
  await sleep(2500);

  // 2. 填元素选择器（方式 C）
  const s1 = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  const combo = s1.text.split("\n").find(l => /\d+\s+组合框\s+\(settable,\s*string\)/.test(l) && !/Description|页/.test(l));
  const comboIdx = parseInt(combo.match(/^\s*(\d+)/)[1]);
  await sky.click({ app: "com.google.Chrome", element_index: comboIdx });
  await sleep(500);
  await sky.press_key({ app: "com.google.Chrome", key: "cmd+v" });
  await sleep(1500);
  await sky.click({ app: "com.google.Chrome", element_index: comboIdx });
  await sleep(400);
  await sky.press_key({ app: "com.google.Chrome", key: "Return" });
  await sleep(1500);

  // 3. 点"+ 添加"输出参数
  const s2 = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  const addBtn = s2.text.split("\n").find(l => /按钮\s+plus\s+添加/.test(l));
  const addIdx = parseInt(addBtn.match(/^\s*(\d+)/)[1]);
  await sky.click({ app: "com.google.Chrome", element_index: addIdx });
  await sleep(1500);

  // 4. 立即（同一 exec）拿新输入框 idx 填参数名和参数值
  const s3 = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  const inputs = s3.text.split("\n").filter(l => /文本输入区.*settable/.test(l) && !/编辑器容器|请输入|Enter/.test(l));
  const nameIdx = parseInt(inputs[0].match(/^\s*(\d+)/)[1]);
  const valueIdx = parseInt(inputs[1].match(/^\s*(\d+)/)[1]);
  await sky.click({ app: "com.google.Chrome", element_index: nameIdx });
  await sleep(500);
  await sky.type_text({ app: "com.google.Chrome", text: "titles" });
  await sleep(600);
  await sky.click({ app: "com.google.Chrome", element_index: valueIdx });
  await sleep(500);
  // ${title} 含特殊字符 $ 与 { }，type_text 支持 ASCII 均可
  await sky.type_text({ app: "com.google.Chrome", text: "$" });
  await sleep(200);
  await sky.type_text({ app: "com.google.Chrome", text: "{title}" });
  await sleep(600);

  // 5. 保存
  const s4 = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  const saveLine = s4.text.split("\n").find(l => /按钮\s+保\s*存/.test(l));
  const saveIdx = parseInt(saveLine.match(/^\s*(\d+)/)[1]);
  await sky.click({ app: "com.google.Chrome", element_index: saveIdx });
  await sleep(2000);
  nodeRepl.write("loopelements-saved");
}
```

## 常见踩坑

| 现象 | 原因 | 修复 |
|---|---|---|
| canvas 节点显示"选择器未配置" | `selector` XPath 未落库或 outputList 为空 | 双击重开弹框，用方式 C 补齐 XPath；输出参数至少 1 行 |
| 循环运行 0 次 | XPath 匹配到 0 个元素 | curl 抓页面 static HTML 验证元素是否 SSR；或先加"截图/等待元素存在"节点确认页面加载完 |
| 子指令拿到的都是第 1 个元素文本 | 子指令 XPath 用了固定路径而非 `@{loopResult.index}` | 改成 `(...)[@{loopResult.index}]` 引用当前索引 |
| 输出为空 `${loopResult.titles}=[]` | outputList `value` 引用了循环外变量或未定义变量 | value 必须引用循环体内**子指令的 outKey**（如 GetText 的 outKey="title" → value="${title}"） |
| "输出参数"表格新加行的输入框 sky idx 失效 | AntD Table virtual scroll，每次 diff idx 都变；跨 sky exec 边界 idx 全部失效 | **同一次 sky exec 内**完成"点添加+填名称+填值"，不要拆多 exec |
| `${title}` 保存时报警告"未定义变量" | 循环体子指令还没加，先加子指令再配 outputList | 顺序：先加子指令（GetText outKey=title）→ 再进循环节点配 outputList |

## 关联模块

- 需要元素选择器时：[element-selector.md](../element-selector.md)（方式 C 首选）
- 循环内子指令：[gettext.md](gettext.md)、[getelementattribute.md](getelementattribute.md)、[clickelementmixed.md](clickelementmixed.md)
- 场景样例：[scenarios/loop-elements-xhs.md](../scenarios/loop-elements-xhs.md)（小红书首页遍历标题）
- 调试失败：[debug.md](../debug.md)
