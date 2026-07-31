# 元素选择器配置

> ⚠️ **绝对不要凭先验知识猜 XPath/CSS Selector。** 必须先通过下面流程从真实 DOM 获取准确值，再填入 filltext / clickelementmixed 的「元素选择器」字段。

> ⚠️ **步骤衔接**：粘贴、点 close、点「为定位器」等**每个动作后**全量抓 AX Tree 验证。完整逐步示例见 **`reference/ax-verify.md`** §示例 Step B–D。

## 批量采集（新建 Tab · 推荐）

本次任务若需要元素 XPath 定位（FillText、ClickElement 等），**配置表单前**先在浏览器**新建 Tab** 打开目标页，**一次性采集完本任务所需的全部元素定位信息**，再切回工作流 Tab 逐条填表。

> ⚠️ **禁止**在工作流编排 Tab 的地址栏直接导航到目标站——会丢失 canvas 编辑状态。须 **Cmd+T 新建 Tab** 探测，采完切回。

### 何时触发

- 场景涉及「输入文本」「点击元素」等需「元素选择器」的指令
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

切回工作流 Tab 后，按 `element-selector.md` **方式 C1** 将 XPath 填入各指令「元素选择器」，**本任务涉及的选择器在本轮内全部填完**，再进入调试。

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

## 方式 B：平台录制捕获（VNC 云浏览器）

1. 设备区连接云浏览器 Chrome（「云浏览器」→ 双击「Chrome」）
2. 双击指令节点 → 点「捕获」→ 状态变为「采集中」
3. 在 VNC 中导航到目标页，悬停目标元素（有 hover 高亮）→ 点击 → 「完成」
4. 验证采集到正确元素类型（如 `<textarea>` 而非外层 `<div>`）

> ⚠️ 若无 hover 高亮：关闭弹框，重新双击节点，再次点「捕获」

## 方式 C：手动填写 XPath/CSS Selector

### C1：元素选择器输入框直接输入 XPath（仅支持 XPath）

手动输入 XPath 的完整流程：

```
1. 聚焦「元素选择器」输入框 → pbcopy + cmd+v 粘贴 XPath
2. 若下拉出现「未找到匹配结果」→ 点击输入框右侧 close icon（×）关闭下拉
3. 输入完成后等待 1s
4. 出现蓝色「以 //xxx 为定位器」选项 → 点击该选项
5. 确认输入框无红色边框 → 再点弹框右下角「保存」
```

| 步骤 | UI 现象 | 操作 |
|------|---------|------|
| 粘贴 XPath | 下拉可能显示「**未找到匹配结果**」 | 点输入框**右侧 close icon（×）** 关闭无效下拉 |
| 等待 | 约 1s 后 | 下拉刷新，出现「**以 //xxx 为定位器**」 |
| 确认 | 输入框红框消失 | 再保存 |

> ⚠️ 「未找到匹配结果」是元素库搜索无命中，**不代表 XPath 无效**；关 dropdown 后等平台生成「为定位器」建议即可。
> ⚠️ 跳过「为定位器」直接保存会报「该字段是必填字段」，输入框保持红色边框。

**sky 自动化**：按 `ax-verify.md` Step B → C → D 逐步执行，**禁止**合并为单块无验证脚本。核心循环：

```js
// 动作
await sky.click({ app: "com.google.Chrome", element_index: idx });
// 验证（必须）
const lines = (await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true })).text.split("\n");
nodeRepl.write(JSON.stringify({ ok: lines.some(/* 本步成功信号 */) }));
```

### C2：「新建」→「属性定义」→ type 选 CSS

需要 CSS selector 时使用；在 value 输入框填写精确 selector 后点「确认」。
