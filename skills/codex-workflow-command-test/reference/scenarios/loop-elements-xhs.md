# 场景 E：循环遍历元素（LoopElements）· 小红书首页输出笔记标题

**目标**：用 `LoopElements` 指令遍历小红书 explore 页首屏所有笔记，把标题批量收集到数组变量后打印输出。

**工作流命名建议**：`循环遍历-小红书首页-YYYYMMDD`

**触发关键词**：循环遍历元素、LoopElements、小红书循环、遍历页面元素、批量抓取标题、`@{toolId.index}`、outputList 测试

---

## 场景背景

- **测试目标页**：`https://www.xiaohongshu.com/explore`（云浏览器内网可访问）
- **标题元素**：`<a class="title"><span>笔记标题</span></a>`，SSR HTML 里首屏 **32 条**（curl 抓取已确认）
- **XPath 策略**：`//a[@class="title"]` — 精确匹配 class="title" 的 a 标签，纯 ASCII 好落库

---

## 指令节点表

| 序号 | 指令 | reference | 关键配置 |
|------|------|-----------|---------|
| 1 | 打开网页 | [openurl.md](../commands/openurl.md) | 网址：`https://www.xiaohongshu.com/explore` |
| 2 | 循环遍历元素 | [loopelements.md](../commands/loopelements.md) | selector: `//a[@class="title"]`；outputList 表格加一行 `titles / ${title}`；outKey 默认 `loopResult` |
| 2.1 | └ GetText（循环体内子指令） | [gettext.md](../commands/gettext.md) | selector: `(//a[@class="title"])[@{loopResult.index}]`；outKey: `title` |
| 3 | 打印日志（循环节点之后）| [comment.md](../commands/comment.md) | 日志内容：`${loopResult.titles}` |

---

## 完整 XML DSL（等价配置）

```xml
<OpenUrl url="https://www.xiaohongshu.com/explore" />

<LoopElements
  selector='//a[@class="title"]'
  outputList='[{"name":"titles","value":"${title}"}]'
  toolId="loopResult"
  outKey="loopResult">
  <GetText
    selector='(//a[@class="title"])[@{loopResult.index}]'
    outKey="title"/>
</LoopElements>

<Comment message="${loopResult.titles}" />
```

---

## 执行步骤（按 [test-workflow.md](../test-workflow.md) 标准流程）

### 第 1 步 · 打开网页

- 网址粘贴 `https://www.xiaohongshu.com/explore`（[url-input.md](../url-input.md)）

### 第 2 步 · 加循环遍历元素节点并配置

1. 选中「打开网页」节点 → Enter 创建空行
2. 右侧搜索框输入 `循环遍历`，双击「网页自动化 → 元素操作」下的 **循环遍历 元素**（中间有空格）
3. 弹框内 **[常规] Tab**：
   - **元素选择器**：`pbcopy` + `Cmd+V` 粘贴 `//a[@class="title"]` → **Enter** 让 AntD Select 落库
   - **循环变量信息**（只读表格）：确认自动生成 `index / number` 一行
   - **输出参数**：点「**+ 添加**」新增 1 行：
     - 参数名称：`titles`
     - 参数类型：保持默认 `array<string>`
     - 参数值：`${title}`（引用下一步 GetText 子指令的 outKey）
4. **暂不保存**——先切到 [高级] Tab 检查 `toolId=loopResult`（默认即可）与 `outKey=loopResult`
5. 保存

### 第 3 步 · 循环体内加 GetText 子指令

1. 单击 canvas 里的「循环遍历元素」节点行 → 按 **Enter** → 循环节点内部出现"通过输入或者从指令列表拖拽添加指令"空槽
2. 右侧搜索框搜 `获取文本` → 双击 (web) 结果
3. 弹框配置：
   - **元素选择器**：`(//a[@class="title"])[@{loopResult.index}]`（用 pbcopy+Cmd+V+Enter；含 `@{}` 是 rpa 平台自动注入的循环索引，从 1 开始）
   - **将结果保存至（outKey）**：`title`（点弹框内输出参数区可修改默认变量名，改为 `title`）
4. 保存
5. 保存后**验证 canvas**：GetText 节点是**缩进在循环节点内**的子节点，不是紧跟其后的同级节点（否则 outputList 拿不到 title）

### 第 4 步 · 循环节点之后加打印日志

1. 单击 canvas 里「循环遍历元素」节点行 → Enter 创建**外层**空行（不进入循环体）
2. 搜「打印日志」双击
3. **日志内容**：`${loopResult.titles}`（pbcopy+Cmd+V；`${}` 是循环外访问 outputList 的语法）
4. 保存

### 第 5 步 · 检查 + 调试

- 点顶部「**检查**」→ 无「配置异常节点」
- 点「**调试**」→ 弹框点「**运行**」
- 等待完成（约 20~30s）

---

## 预期结果

聊天区日志：

```
开始节点          ✅ ~7ms
打开网页(web)     ✅ ~4s   https://www.xiaohongshu.com/explore
循环遍历元素       ✅ ~16s  loopTimes=32, errorCount=0
  └ GetText     × 32 次   每次拿到当前 <a class="title"> 内的文本
打印日志          ✅ ~10ms
   日志内容：["小猫明明避障能力那么强，为什么要踩我","黄武靖，95后，清华博士，已任福州市水利局副局长",...共 32 条]
结束节点          ✅
```

## 已实测的验收数据

- 循环节点 XPath `//a[@class="title"]` 在小红书 explore 页命中 **32 个匹配**
- 循环节点耗时 **16.2s**（≈32 × 500ms/次），说明循环真实迭代到位
- SSR HTML `curl -A 'Mozilla/5.0' https://www.xiaohongshu.com/explore | grep -oE '<a[^>]*class="title"[^>]*>[^<]*'` 可**本地验证元素数量**，与循环 loopTimes 对齐

---

## 常见踩坑（本场景专属）

| 现象 | 修复 |
|---|---|
| GetText 每次都拿到第 1 个笔记的标题 | 子指令 XPath 未用 `@{loopResult.index}`。改成 `(//a[@class="title"])[@{loopResult.index}]` |
| `${loopResult.titles}` 打印结果是 `[null, null, ...]` | GetText 的 outKey 名称与 outputList value 引用的变量名不一致；确认两者都是 `title` |
| GetText 节点不在循环内部（成为循环节点的同级节点） | 加子指令前 **必须先 Enter 循环节点**使内部空槽激活；用[insert-command.md §插入位置约束](../insert-command.md) |
| 打印日志的日志内容输入区无法用 sky.type_text 触发变量弹层 | 该输入区是简单 textarea 不是 Monaco，直接 pbcopy + Cmd+V 粘贴 `${loopResult.titles}` ASCII 字符串即可 |
| 输出参数表格新加行的 sky.click idx 立即失效 | AntD Table virtual scroll，跨 sky exec 边界 idx 全部作废。**同一次 exec 完成"点添加+填名称+填值"三步**（见 [loopelements.md §自动化配置示例](../commands/loopelements.md#自动化配置示例)） |
| 打开小红书页面后循环 0 次 | 云浏览器 UA 可能被识别为爬虫返回登录页。加"等待元素存在 //a[@class='title']"节点前置，超时 5000ms |

---

## 通用扩展

- **收集多字段**：outputList 加多行如 `[{"name":"titles","value":"${title}"},{"name":"links","value":"${link}"}]`；循环体再加一个 `GetElementAttribute` 拿 href
- **翻页/滚动加载**：设置 `loadMoreAction=SCROLL_DOWN` + `loadMoreWaitTime=2000` + `maxLoopTimes=100`
- **过滤条件**：循环内加 `Assert` 或 `Break` 提前跳出

见 [loopelements.md](../commands/loopelements.md) 的 XML DSL 示例 B / C。

---

## 关联

- 指令参数：[commands/loopelements.md](../commands/loopelements.md)
- 元素选择器：[element-selector.md](../element-selector.md)（方式 C 首选）
- 循环体插入：[insert-command.md](../insert-command.md)
- 报错对照：[debug.md](../debug.md)
