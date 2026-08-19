# 用户意图解析（最高优先级）

> 🚫🚫🚫 **硬性规则**：用户消息中**明确声明的指令名**，优先级**高于**场景文件默认值、技能默认场景、以及示例脚本里的硬编码搜索词。
>
> **禁止**用户写了「导航到url」却搜索/插入「打开网页」；**禁止**用户写了「点击元素」却换成「点击」以外的近似指令（除非平台无精确匹配）。

## 优先级（从高到低）

```
1. 用户消息中显式指定的指令序列（最高）
2. 用户指定的测试站点 / 场景（仅决定 URL、XPath、locators；不覆盖指令名）
3. 场景 reference/scenarios/<场景>.md 的默认指令表
4. 技能默认场景 bilibili.md（仅当用户完全未指定场景与指令）
```

## 执行前必做：解析 instructionPlan

**在** Read 场景文件、**在**搜索框粘贴指令名、**在**插入第一条指令**之前**，从用户消息提取并输出 `instructionPlan`：

```json
{
  "site": "sogou",
  "targetUrl": "https://www.sogou.com/",
  "userSpecifiedCommands": true,
  "instructionPlan": [
    { "searchName": "导航到URL", "platformName": "导航到URL", "reference": "commands/navigatetourl.md", "urlField": "导航到的网址" },
    { "searchName": "输入文本", "platformName": "输入文本", "reference": "commands/filltext.md" },
    { "searchName": "点击", "platformName": "点击元素（推荐）", "reference": "commands/clickelementmixed.md" }
  ]
}
```

> `userSpecifiedCommands === true` 时：**只插入 instructionPlan 列出的指令**，不得擅自追加场景默认里的「刷新网页」等用户未提及的步骤。

## 用户表述 → 平台搜索名映射

| 用户可能说 | 平台搜索框输入 | 指令标识 | reference | 禁止替换为 |
|-----------|--------------|---------|-----------|-----------|
| 导航到url / 导航到URL / NavigateToUrl / 导航到网址 | **`导航到URL`** | `NavigateToUrl` | `navigatetourl.md` | ❌ 打开网页 |
| 打开网页 / OpenUrl / open url | **`打开网页`** | `OpenUrl` | `openurl.md` | ❌ 导航到URL |
| 输入文本 / FillText | **`输入文本`** | `FillText` | `filltext.md` | — |
| 点击 / 点击元素 / ClickElement | **`点击`** 或 **`点击元素`** | `ClickElementMixed` | `clickelementmixed.md` | — |
| 刷新网页 / ReloadPage | **`刷新网页`** | `ReloadPage` | `reloadpage.md` | — |
| 验证元素存在 | **`验证元素存在`** | `VerifyElementPresent` | `verifyelementpresent.md` | — |

完整 98 条见 `commands/index.md`；用户提到但未在上表的指令，按 `commands/index.md`「平台指令名」列精确匹配。

## 易混淆：打开网页 vs 导航到URL

| | 打开网页 (`OpenUrl`) | 导航到URL (`NavigateToUrl`) |
|--|---------------------|----------------------------|
| 平台搜索 | `打开网页` | `导航到URL` |
| 弹框必填字段 | `* 网址` | `* 导航到的网址` |
| 语义 | 新开页面打开 URL | 当前浏览器实例内导航（无页面则新建） |
| 用户指定后者时 | **禁止**用前者代替 | 必须用 `导航到URL` 搜索并双击 |

URL 填写均走 `url-input.md`（scoped 定位弹框字段，禁止 Chrome 地址栏）；`NavigateToUrl` 的 label 为 `* 导航到的网址`。

## 站点与 URL（不覆盖指令名）

用户只给站点、未给完整 URL 时，从场景/locators 补 URL，**但不改指令名**：

| 用户站点关键词 | 读场景 | 默认 URL |
|--------------|--------|---------|
| sogou / 搜狗 | `scenarios/sogou.md` | `https://www.sogou.com/` |
| baidu / 百度 | `scenarios/baidu.md` | `https://www.baidu.com` |
| bilibili / B站 | `scenarios/bilibili.md` | `https://www.bilibili.com` |

## 示例

### 示例 A（如图 · 必须遵守）

**用户**：`/codex-workflow-command-test 以 sogou.com 为场景测试导航到url，输入文本、点击元素指令`

**解析**：

- 站点：sogou → URL `https://www.sogou.com/`，XPath 读 `scenarios/sogou.md`
- 指令：**导航到URL → 输入文本 → 点击**（3 条；用户未提「刷新」→ **不插**刷新网页）
- 第 1 条搜索框：`导航到URL`（**不是** `打开网页`）
- 第 1 条配置：Read `navigatetourl.md`，填 `导航到的网址`

**错误做法** ❌：读 sogou.md 默认表第 1 行「打开网页」并搜索 `打开网页`

### 示例 B（仅指定场景）

**用户**：`搜狗场景测试`

→ Read `scenarios/sogou.md`，使用场景**默认**四步：打开网页 → 输入文本 → 点击 → 刷新

### 示例 C（指定场景 + 部分指令）

**用户**：`百度场景，用导航到URL代替打开网页`

→ 站点 baidu；第 1 步强制 `导航到URL` + `https://www.baidu.com`；其余按 baidu.md

## 与 insert-command / 终检 的衔接

1. **搜索框**（`insert-command.md` §第 2 步）：`query = instructionPlan[i].searchName`，**禁止**写死 `"打开网页"`
2. **双击验证**：匹配 `(web)` 结果时用 `instructionPlan[i].platformName`，如 `/导航到URL\s*\(web\)/`
3. **顺序终检**（`ax-verify.md` §插入后顺序校验）：首条页面类指令可以是 `打开网页` **或** `导航到URL`；用 `hasPageOpenCmd` 代替仅检查 `打开网页`
4. **调试前终检**（`test-workflow.md`）：`scenario` 数组来自 `instructionPlan.map(x => x.platformName)`，不是场景文件硬编码

## sky：从 instructionPlan 搜索插入

```js
{
  // 当前要插入的第 i 条（0-based），来自 user-intent.md 解析结果
  const instructionPlan = [
    { searchName: "导航到URL", platformName: "导航到URL" },
    { searchName: "输入文本", platformName: "输入文本" },
    { searchName: "点击", platformName: "点击元素（推荐）" },
  ];
  const i = 0;
  const query = instructionPlan[i].searchName; // ← 禁止 fallback 到 "打开网页"

  const { execFileSync } = await import("node:child_process");
  execFileSync("/usr/bin/pbcopy", { input: query });
  // ... insert-command.md 搜索框 click → cmd+v ...
  const s1 = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  const escaped = instructionPlan[i].platformName.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const hasResult = new RegExp(`${escaped}\\s*\\(web\\)`).test(s1.text);
  nodeRepl.write(JSON.stringify({ step: "search-by-intent", query, hasResult, userSpecified: true }));
}
```

## 违规对照

| 用户说了 | Agent 做了 | 判定 |
|---------|-----------|------|
| 导航到url | 搜索「打开网页」 | ❌ 违反用户意图 |
| 导航到URL + 输入文本 + 点击 | 额外插入「刷新网页」 | ❌ 用户未要求 |
| 仅「工作流指令测试」 | 直接用 bilibili 默认 | ✅ 无显式指令时可默认 |
| sogou + 导航到url | sogou URL + 导航到URL 搜索 | ✅ 正确 |
