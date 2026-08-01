# 元素选择器配置

> ⚠️ **绝对不要凭先验知识猜 XPath/CSS Selector。** 必须先通过下面流程从真实 DOM 获取准确值，再填入 filltext / clickelementmixed / verifyelement* 等指令的「元素选择器」字段。

> ⚠️ **仅两种写入方式**：**方式 B（平台捕获）** 或 **方式 C（粘贴 XPath + Enter）**。其他方式（点击「以…为定位器」下拉、DevTools React setter、type_text 逐字符输入、切换 CSS selector 属性定义等）在本平台**不稳定**或**已废弃**，禁止使用。

> ⚠️ **步骤衔接**：粘贴、按 Enter、点保存等**每个动作后**全量抓 AX Tree 验证。完整逐步示例见 **`reference/ax-verify.md`** §示例 Step B–D。

## 批量采集（新建 Tab · **强制前置**）

> 🚫 **强制前置**：含元素选择器的**任意**指令（含 FillText、ClickElementMixed、VerifyElementPresent、VerifyElementVisible、VerifyElementAttributeValue、VerifyElementHasAttribute、VerifyElementNotPresent、VerifyElementNotVisible、WaitForElement\*、GetText、GetElementAttribute、ScrollToElement、MouseOver 等断言/等待类）在**配置表单前**必须先完成本节采集。

**配置表单前**先在浏览器**新建 Tab** 打开目标页，**一次性采集完本任务所需的全部元素定位信息**，再切回工作流 Tab 逐条填表。

> ⚠️ **禁止**在工作流编排 Tab 的地址栏直接导航到目标站——会丢失 canvas 编辑状态。须 **Cmd+T 新建 Tab** 探测，采完切回。

### 何时触发

- 场景涉及含「元素选择器」字段的**任意**指令（不仅限于输入文本/点击，断言类、等待类同样适用）
- `reference/locators/<site>.elements.json` 缓存缺失、过期（>7 天）、或与调试环境 DOM 不符
- 调试报「元素不存在 / FillText 失败」需重采

### 流程概览

```
1. Read 场景文件（scenarios/<场景>.md）→ 列出本任务需要的全部元素（搜索框、按钮…）
2. 优先 Read locators 缓存；若不可用 → 进入新建 Tab 采集
3. Chrome 新建 Tab（Cmd+T）→ 打开目标 URL → 等待页面加载
4. DevTools Console 批量探测 → 记录每个元素的准确 XPath
5. （可选）更新 locators 缓存：bash scripts/update-locators.sh <site>
6. 切回 bots/rpa 工作流 Tab → 用采集到的 XPath 逐条配置指令表单
```

### 步骤详解

**第 1 步：列出本任务所需元素**

对照 `reference/scenarios/<场景>.md`「指令节点」与「元素选择器」表，一次性列出例如：

| 用途 | 对应指令 | 需采集 |
|------|---------|--------|
| 搜索框 | 输入文本 | ✅ |
| 搜索/提交按钮 | 点击元素 | ✅ |

**第 2 步：新建 Tab 打开目标页**

```js
{
  // 工作流 Tab 保持不动；新建 Tab 用于探测
  await sky.press_key({ app: "com.google.Chrome", key: "cmd+t" });
  await new Promise(r => setTimeout(r, 800));

  const s = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  const addrLine = s.text.split("\n").find(l => /settable, string/.test(l) && /地址/.test(l));
  const addrIdx = parseInt((addrLine || "10 ").match(/^\s*(\d+)/)[1]);
  await sky.set_value({ app: "com.google.Chrome", element_index: addrIdx, value: "https://目标网址" });
  await sky.press_key({ app: "com.google.Chrome", key: "Return" });
  await new Promise(r => setTimeout(r, 2500));
}
```

> 多页场景（如首页 + 搜索结果页）：在同一探测 Tab 内依次导航各 URL，**一次性采完**再关 Tab；或按页新建 Tab，但须在本轮配置前汇总全部 XPath。

**第 3 步：DevTools Console 批量探测**

1. `Cmd+Alt+J` 打开 DevTools Console，焦点到 Console 输入框
2. 按站点/场景执行探测脚本（见下文「站点探测脚本」）
3. 从 Console 输出构造每个目标元素的 XPath（有 `id` 优先，其次 `name`/`class`）
4. 将结果整理为清单，供后续填表：

```
本任务 XPath 清单（示例 · Bilibili）：
- 搜索框：//input[contains(@class,"nav-search-input")]
- 搜索按钮：//button[contains(@class,"nav-search-btn")]
```

**第 4 步：切回工作流 Tab**

```js
{
  // 点选 bots/rpa 工作流 Tab，或 Cmd+Shift+Tab 切回
  await sky.press_key({ app: "com.google.Chrome", key: "cmd+Shift+Tab" });
  await new Promise(r => setTimeout(r, 500));
  const s = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  const onWorkflow = s.text.includes("编辑器容器") || s.text.includes("开始节点");
  nodeRepl.write(JSON.stringify({ step: "back-to-workflow", onWorkflow }));
}
```

探测 Tab 可保留供对照，或 `Cmd+W` 关闭。

**第 5 步：用清单配置全部指令**

切回工作流 Tab 后，按优先级 **方式 B（平台捕获）→ 方式 C（粘贴 XPath + Enter）** 将 XPath 填入各指令「元素选择器」，**本任务涉及的选择器在本轮内全部填完**，再进入调试。

### 站点探测脚本

**通用可见控件扫描**（B 站等未知结构站点）：

```bash
echo -n 'JSON.stringify(Array.from(document.querySelectorAll("input,textarea,button")).filter(el=>el.offsetParent!==null).map(el=>({tag:el.tagName,id:el.id,cls:el.className.substring(0,80),type:el.type||"",placeholder:el.placeholder||""})))' | pbcopy
```

粘贴到 Console 执行 → 从输出中识别搜索框、按钮 → 构造 XPath。

**百度专用 variant 探测**（见下节）——云浏览器与本地 DOM 可能不同，探测 Tab 应尽量模拟**实际调试环境**；若只能在本地 Chrome 探测，调试失败时须在云浏览器 VNC 内复探。

### 与 locators 缓存的关系

| 情况 | 做法 |
|------|------|
| 缓存存在且 <7 天、与场景匹配 | Read JSON，**仍可**新建 Tab 快速验证 visible |
| 缓存缺失 / 过期 / 调试失败 | 新建 Tab 批量采集 → 可选 `update-locators.sh` 写回缓存 |
| 多元素任务 | **一次 Tab 会话采齐**，不要配一条采一条 |

详见 `reference/locators/README.md`。

## 百度搜索框探测（配置 FillText 前必做）

同一 URL `https://www.baidu.com/` 可能渲染**经典版**（`#kw`）或**智能输入版**（`#chat-textarea`）。**云浏览器常见后者**。

在云浏览器 DevTools Console 执行：

```javascript
JSON.stringify(['kw','chat-textarea','su','chat-submit-button'].map(id=>{
  const el=document.getElementById(id);
  if(!el) return {id,present:false};
  const r=el.getBoundingClientRect();
  const vis=r.width>0&&r.height>0&&getComputedStyle(el).display!=='none'&&getComputedStyle(el).visibility!=='hidden';
  return {id,present:true,visible:vis,tag:el.tagName,w:Math.round(r.width)};
}))
```

| 探测结果 | 搜索框 XPath | 百度一下按钮 XPath |
|---------|-------------|-------------------|
| `chat-textarea` visible | `//*[@id="chat-textarea"]` | `//*[@id="chat-submit-button"]` |
| `kw` visible | `//*[@id="kw"]` | `//*[@id="su"]` |

> 若两者都 `visible:false` 或都不存在 → 页面未加载完或触发验证，先等加载/重开再探测。
> **禁止**因 URL 无 `/s?` 就假定必须用 `#kw`。

## 方式 A：DevTools Console 采集真实 DOM

> **推荐路径**：见上文 **§批量采集（新建 Tab）**——新建 Tab 打开目标页，一次性采齐本任务全部 XPath，再切回工作流 Tab。
>
> 已知站点（百度、B 站）优先 Read 缓存：`reference/locators/<site>.elements.json`；缓存不可用或需验证时走新建 Tab 采集。
> 实时写回缓存：`bash scripts/update-locators.sh <site>`

### 方式 A-legacy：当前 Tab 地址栏导航（不推荐）

> ⚠️ 工作流编排页已打开时**勿用**——会离开 canvas。仅在没有工作流 Tab 或已在独立探测 Tab 时使用。

1. **在 Chrome 地址栏打开目标网页**（采集完切回 bots 工作流 tab）：
   ```js
   const s = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
   const addrBar = s.text.split("\n").find(l => l.includes("地址和搜索栏"));
   const addrIdx = parseInt((addrBar || "").match(/^\s*(\d+)/)?.[1]);
   await sky.set_value({ app: "com.google.Chrome", element_index: addrIdx, value: "https://目标网址" });
   await sky.press_key({ app: "com.google.Chrome", key: "Return" });
   await new Promise(r => setTimeout(r, 2000));
   ```

2. **打开 DevTools Console（Cmd+Alt+J），焦点到 Console 输入框**

3. **pbcopy + cmd+v 粘贴 JS 查询命令并执行**（不能用 `type_text`）：
   ```bash
   echo -n 'JSON.stringify(Array.from(document.querySelectorAll("input,textarea,button")).filter(el=>el.offsetParent!==null).map(el=>({tag:el.tagName,id:el.id,cls:el.className.substring(0,60),type:el.type||""})))' | pbcopy
   ```

4. **从 AX tree 读取 Console 输出，构造 XPath**：
   - 有 `id` 优先：`//textarea[@id="chat-textarea"]`
   - 无 `id` 用 class：`//input[contains(@class,"nav-search-input")]`

5. **切回 bots 工作流 tab**，关闭 DevTools

## 方式 B：平台「捕获」按钮（**默认策略**）

> **AntD Select/Combobox 环境下优先使用本方式**——「捕获」通过云浏览器 VNC 录制，绕过 React 合成事件，直接落库，是最稳健的写入路径。
>
> **完整流程已独立为模块**：Read **[reference/capture-element.md](capture-element.md)**，按其中 6 步流程执行。该模块是捕获元素的唯一事实来源，其他模块需要捕获时也调用它。

### 快速概览（详细步骤见 capture-element.md）

```
1. 验证配置弹框已打开（多信号交叉验证：有捕获按钮 / 有元素选择器 / 有保存按钮）
2. 点击弹框内「捕获」按钮 → 等待采集中状态
3. 在云浏览器中点击目标元素 → 验证 XPath 回填
   - XPath 不正确时可：重选 / 大选区 / 缩小选取
4. 点击保存 → 验证弹框关闭
5. 回到编排区验证元素是否回显在指令上
6. 未捕获成功 → 刷新页面 → 重新双击指令 → 重新捕获（循环，上限 3 次）
```

### 判据原则（⚠️ 必读）

**禁止**使用单一精确字符串匹配判断弹框/按钮状态。AX Tree 中的空格可能是 tab/nbsp 而非普通空格，`includes` 对不可见字符零容忍。

| 判定目标 | ❌ 错误判据 | ✅ 正确判据 |
|---------|-----------|-----------|
| 弹框已打开 | 标题字符串精确匹配 | 有「捕获」按钮 **OR** 有「元素选择器」字段 **OR** 有「保存」按钮 |
| 捕获按钮 | `l.includes("捕获")` | `/\d+\s+按钮\s+捕\s*获/.test(l)` |

详细判据规范和完整 sky 自动化脚本见 **`capture-element.md`**。

## 方式 C：粘贴 XPath + Enter（AntD Select 唯一有效的手工输入方式）

**适用场景**：方式 B（捕获）不可用（无捕获按钮 / 云浏览器断线 / 已在批量采集里拿到 XPath），需要直接把已知 XPath 填进「元素选择器」输入框。

**原理**（一句话）：AntD Select 是受控组件，剪贴板 `Cmd+V` 只改 DOM value，不触发 React onChange，弹框「该字段是必填字段」红字持续显示；紧接着按 **Enter** 会触发 AntD 内部的「confirm current input as tag」逻辑——把粘贴文本作为选项值提交给 React state，红字消失，等效于用户手动点了下拉里那条「以 //xxx 为定位器」的确认项。

### 五步流程（不可省略任何一步）

```
1. 找到「元素选择器」组合框（AX 中 `组合框 (settable, string)`，父容器紧跟「* 元素选择器」标签）
2. click 该组合框 → 等 ~400ms
3. Shell 侧 pbcopy XPath → sky press_key Cmd+V 粘贴 → 等 ~1200ms
4. sky press_key Return（Enter）→ 等 ~1500ms
5. 全量抓 AX Tree 校验：
   - ✅ 「该字段是必填字段」文本已消失
   - ✅ 组合框旁出现独立一行 `\d+ text //*[@id="..."]` 或类似 XPath 回显
   - 均满足 → 点弹框「保存」；任一不满足 → 见「失败排查」
```

> 💡 **不必**再去查找、点击下拉里的「以 //xxx 为定位器」选项——Enter 已经等效完成了该点击动作。

### AX 验证信号

| 组合框行 / 附近 AX 文本 | 含义 | 下一步 |
|-----------------------|------|--------|
| 组合框 Value 为空 / 无 XPath 回显文本 | 粘贴未成功 | 重新 click 组合框 → 检查剪贴板 → 重试 Cmd+V |
| 组合框有 XPath 但仍有「该字段是必填字段」 | Cmd+V 已生效但 React onChange 未触发 | **按 Enter**（本方式核心步骤） |
| 组合框旁出现 `\d+ text //*[@id="..."]` 独立行 + 无必填错误 | ✅ Enter 生效，XPath 已被 React state 接受 | 点保存 |
| 保存后仍有「该字段是必填字段」 | Enter 未触发或组合框失焦太早 | 重新聚焦组合框 → Cmd+V → **确保 Enter 在同一次聚焦内触发** |

### sky 自动化模板

```js
{
  // 前置：Shell 侧已执行 echo -n '//*[@id="xxx"]' | pbcopy
  const s = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  const lines = s.text.split("\n");
  // 定位「* 元素选择器」标签
  const labelIdx = lines.findIndex(l => /text\s+\*\s+元素选择器/.test(l));
  // 在标签下方 20 行内找组合框
  const comboLine = lines.slice(labelIdx, labelIdx + 20)
    .find(l => /组合框\s+\(settable, string\)/.test(l));
  const comboIdx = comboLine ? parseInt(comboLine.match(/^\s*(\d+)/)[1]) : null;

  await sky.click({ app: "com.google.Chrome", element_index: comboIdx });
  await new Promise(r => setTimeout(r, 500));
  await sky.press_key({ app: "com.google.Chrome", key: "Command+v" });
  await new Promise(r => setTimeout(r, 1200));
  await sky.press_key({ app: "com.google.Chrome", key: "Return" });
  await new Promise(r => setTimeout(r, 1500));

  const s1 = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  const hasErr = /该字段是必填字段/.test(s1.text);
  const hasValue = /text\s+\/\/.*chat-textarea/.test(s1.text) ||
    /text\s+\/\//.test(s1.text);  // 按实际 XPath 模式调整
  nodeRepl.write(JSON.stringify({ comboIdx, hasErr, hasValue, ok: !hasErr && hasValue }));
}
```

### 失败排查

| 现象 | 原因 | 处理 |
|------|------|------|
| Enter 后组合框失去焦点但红字仍在 | Enter 触发时输入框已失焦 | 重新 click 组合框 → 立即 Cmd+V → 立即 Return（三步紧凑） |
| 组合框始终无 value | 剪贴板被覆盖（如用户消息、其他 pbcopy） | 重新 `echo -n '<XPath>' \| pbcopy` → 再 Cmd+V |
| 保存报「该字段是必填字段」 | Enter 步骤被跳过 | 补做 Enter 后再保存 |
| Enter 后弹框意外关闭 | 焦点错误落在「保存」按钮上 | 检查组合框 idx；使用 focus 后再 Cmd+V |
| XPath 含中文或非 ASCII | pbcopy 传输正常但 AntD Select 拒收 | 换纯 ASCII XPath；或使用**方式 B（平台捕获）** |

### 与方式 B 的取舍

| 情况 | 首选 |
|------|------|
| 平台配置弹框内**有**「捕获」按钮 + 云浏览器在线 | **方式 B** |
| 无捕获按钮（如某些断言指令弹框）/ 云浏览器断线 / 已在批量采集拿到全套 XPath | **方式 C** |
| 首次尝试方式 B 失败 3 次以上 | 切换到方式 C 兜底 |

> ⚠️ **禁止**：混合调用；一次填表只用一种方式。方式 B 未成功时不要保留半吊子状态再切方式 C——先在弹框内清空选择器输入框（Cmd+A → Delete）再走方式 C。
