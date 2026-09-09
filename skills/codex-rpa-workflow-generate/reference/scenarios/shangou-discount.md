# 场景：闪购商家后台 — 创建折扣活动

**Plan 文件**：`reference/examples/shangou-discount-plan.json`  
**Plan 类型**：复合 plan（`preSteps` + `ifElse` + `postSteps`，**仅 IF、无 Else**）  
**工作流名称**：`闪购折扣活动创建-20260909`  
**目标 URL**：`https://e.shangou.test.sankuai.com/`

> 本文档是自然语言 → plan → JSON 的**唯一规格说明**。按下列步骤逐条生成，不得增删改序，即可得到与示例 plan 及 `build-composite-workflow.mjs` 输出一致的节点 JSON。

---

## 流程结构（必须先理解）

```
preSteps（2 步）
  → IF 节点（仅当探测节点输出 true 时执行 ifBranch 5 步）
  → postSteps（24 步，通用流程；无登录框时跳过 IF 直接执行）
```

- **不要** Else 节点；`elseBranch` 字段不出现。
- **不要**把通用流程写进 `ifBranch`；登录 5 步之外的全部步骤都在 `postSteps`。
- IF 探测：preSteps 第 2 步 `WaitForElementPresent` 设 `probeForIf: true`。
- 输出：`formData.outKey = ""` + `outKeyType: "Boolean"`（保存到本节点）。
- IF 条件：`${<该步nodeId>} = true`（由 `build-composite-workflow.mjs` 自动绑定）。见 [boolean-outkey-self-node.md](../boolean-outkey-self-node.md)。

---

## 自然语言逐步描述

### 阶段 A：前置（preSteps）

**A1. 打开网页**  
打开 `https://e.shangou.test.sankuai.com/`。

| 字段 | 值 |
|------|-----|
| unionId | `OpenUrl` |
| params.url | `https://e.shangou.test.sankuai.com/` |

**A2. 探测是否需要登录**  
等待登录页「账号输入框」出现，最多 8 秒；若未出现则继续（不中断）。结果**保存到本节点**（outKey 为空），供 IF 判断。

| 字段 | 值 |
|------|-----|
| unionId | `WaitForElementPresent` |
| params.probeForIf | `true` |
| params.timeout | `"8000"` |
| params.failOptions.failureHandling | `"continue"` |
| params.selector.alias | `定位闪购商家后台登录页账号输入框，用于判断是否需要登录` |

---

### 阶段 B：IF 分支（ifBranch，仅 5 步 — 可选登录）

> 仅当 A2 探测到登录框（探测节点输出 `true`）时执行。

**B1. 输入账号**  
在登录页账号输入框输入 `SGtest_yingixao`。

| unionId | `FillText` |
| params.text | `SGtest_yingixao` |
| params.selector.alias | `定位闪购商家后台登录页账号输入框，用于输入登录账号` |

**B2. 输入密码**  
在登录页密码输入框输入 `qwer12345678`。

| unionId | `FillText` |
| params.text | `qwer12345678` |
| params.selector.alias | `定位闪购商家后台登录页密码输入框，用于输入登录密码` |

**B3. 勾选协议**  
点击登录页「同意协议」复选框。

| unionId | `ClickElementMixed` |
| params.selector.alias | `定位闪购商家后台登录页同意协议复选框，用于勾选用户协议` |

**B4. 点击登录**  
点击登录页「登录」按钮。

| unionId | `ClickElementMixed` |
| params.selector.alias | `定位闪购商家后台登录页登录按钮，用于点击提交登录` |

**B5. 等待页面加载**  
等待页面 LOAD 完成，超时 30 秒。

| unionId | `WaitPageState` |
| params.loadState | `LOAD` |
| params.timeout | `"30000"` |

---

### 阶段 C：通用流程（postSteps，24 步）

> IF 执行完或无登录框时，均从 C1 开始顺序执行。

**C1. 侧栏滚动**  
在左侧导航菜单栏容器内向下滚动 600 像素（x=0, y=600）。

| unionId | `ScrollToPosition` |
| params.x | `"0"` |
| params.y | `"600"` |
| params.selector.alias | `定位闪购商家后台左侧导航菜单栏容器，用于向下滚动600像素` |

**C2. 滚动到菜单项**  
将左侧导航「店铺活动」菜单项滚入可见区域（比全页文本断言更稳，避免虚拟列表未渲染）。

| unionId | `ScrollToElement` |
| params.findTimeout | `"15000"` |
| params.selector.alias | `定位闪购商家后台左侧导航栏中的店铺活动菜单项，用于滚动到店铺活动菜单可见区域` |

**C3. 进入店铺活动**  
点击左侧导航「店铺活动」菜单项。

| unionId | `ClickElementMixed` |
| params.selector.alias | `定位闪购商家后台左侧导航栏中的店铺活动菜单项，用于点击进入店铺活动页面` |

**C4. 立即创建折扣**  
在右侧「折扣活动」卡片上点击「立即创建」（含滚动自愈）。

| unionId | `ClickElementMixed` |
| params.selfHealScroll | `true` |
| params.selfHealScrollContainer.alias | `定位闪购店铺活动页面右侧主内容滚动区域，用于自愈滚动以寻找折扣活动立即创建按钮` |
| params.selector.alias | `定位闪购店铺活动页面右侧折扣活动卡片上的立即创建按钮，用于开始创建折扣活动` |

**C4b. 等待新建页加载**  
点击「立即创建」后等待新页面 `LOAD`（最多 30s）。

| unionId | `WaitPageState` |
| params.loadState | `LOAD` |
| params.timeout | `"30000"` |

**C5. 创建折扣活动**  
在新页面点击顶部「创建折扣活动」主按钮（含滚动自愈 + 定位 15s）。

| unionId | `ClickElementMixed` |
| params.selfHealScroll | `true` |
| params.selfHealProbeTimeout | `"5000"` |
| params.findTimeout | `"15000"` |
| params.selfHealScrollContainer.alias | `定位闪购折扣活动新建页面主内容滚动区域，用于自愈滚动以寻找创建折扣活动按钮` |
| params.selector.alias | `定位闪购折扣活动新建页面顶部标题栏右侧的创建折扣活动主按钮，用于点击进入活动配置表单` |

**C6. 打开结束日期**  
点击活动日期区域右侧的「结束时间」输入框，打开日期下拉面板。

| unionId | `ClickElementMixed` |
| params.selector.alias | `定位闪购折扣活动表单中活动日期区域右侧的结束时间输入框，用于打开结束日期下拉面板` |

**C7. 选择明天**  
在日期下拉面板中点击「明天」。

| unionId | `ClickElementMixed` |
| params.selector.alias | `定位闪购活动日期下拉面板中明天的日期选项，用于选择活动结束日期为明天` |

**C8. 添加门店**  
点击「添加门店」按钮，打开门店选择弹框。

| unionId | `ClickElementMixed` |
| params.selector.alias | `定位闪购折扣活动表单中的添加门店按钮，用于打开门店选择弹框` |

**C9. 勾选北京市**  
在弹框中勾选「北京市」。

| unionId | `ClickElementMixed` |
| params.selector.alias | `定位闪购添加门店弹框中北京市选项前的复选框，用于勾选北京市门店` |

**C10. 确认门店**  
点击弹框右下角「确定」。

| unionId | `ClickElementMixed` |
| params.selector.alias | `定位闪购添加门店弹框右下角的确定按钮，用于确认门店选择` |

**C11. 添加商品（含滚动自愈）**

点击「添加商品」按钮；构建前自动插入**链式滚动自愈**（见 [self-heal-scroll.md](../self-heal-scroll.md)）：每改一档偏移后探测一次，元素已可见则停止滚动，否则才尝试下一档。

| unionId | `ClickElementMixed` |
| params.selfHealScroll | `true` |
| params.selfHealScrollContainer.alias | `定位闪购折扣活动表单右侧主内容滚动区域，用于自愈滚动以寻找添加商品按钮` |
| params.selector.alias | `定位闪购折扣活动表单中的添加商品按钮，用于打开添加商品弹框` |

**C12. 选择商品名称筛选**  
在弹框中选择筛选项「商品名称」。

| unionId | `ClickElementMixed` |
| params.selector.alias | `定位闪购添加商品弹框中商品名称筛选项，用于选择按商品名称搜索` |

**C13. 输入搜索词**  
在搜索输入框输入 `手机`。

| unionId | `FillText` |
| params.text | `手机` |
| params.selector.alias | `定位闪购添加商品弹框中的商品搜索输入框，用于输入搜索关键词手机` |

**C14. 选择苹果手机**  
在下拉列表中选择「苹果手机」选项。

| unionId | `ClickElementMixed` |
| params.selector.alias | `定位闪购添加商品弹框搜索条件下拉列表中的苹果手机选项，用于选择苹果手机分类` |

**C15. 执行搜索**  
点击「搜索」按钮。

| unionId | `ClickElementMixed` |
| params.selector.alias | `定位闪购添加商品弹框中的搜索按钮，用于执行商品搜索` |

**C16. 勾选第一个商品**  
勾选搜索结果列表中第一个商品前的复选框。

| unionId | `ClickElementMixed` |
| params.selector.alias | `定位闪购添加商品弹框商品列表中第一个商品前的复选框，用于勾选第一个商品` |

**C17. 确认添加商品**  
点击弹框右下角「确定」。

| unionId | `ClickElementMixed` |
| params.selector.alias | `定位闪购添加商品弹框右下角的确定按钮，用于确认添加所选商品` |

**C18. 滚动到商品列表底部**  
在表单右侧主内容区向下滚动（x=0, y=9999）。

| unionId | `ScrollToPosition` |
| params.x | `"0"` |
| params.y | `"9999"` |
| params.selector.alias | `定位闪购折扣活动表单右侧主内容滚动区域，用于向下滚动到商品列表底部` |

**C19. 打开折扣设置**  
在商品列表中点击「请设置」。

| unionId | `ClickElementMixed` |
| params.selector.alias | `定位闪购折扣活动商品列表中请设置链接或按钮，用于打开商品折扣设置弹框` |

**C20. 输入 9 折**  
在折扣设置弹框的折扣输入框输入 `9`（表示 9 折）。

| unionId | `FillText` |
| params.text | `9` |
| params.selector.alias | `定位闪购商品折扣设置弹框中的折扣输入框，用于输入9折折扣数值` |

**C21. 确认折扣设置**  
点击折扣设置弹框的「确定」或「保存」。

| unionId | `ClickElementMixed` |
| params.selector.alias | `定位闪购商品折扣设置弹框中的确定或保存按钮，用于确认折扣设置` |

**C22. 一键全选商品**  
点击商品列表区域的「一键全选」按钮，选中所有已添加商品。

| unionId | `ClickElementMixed` |
| params.selector.alias | `定位闪购折扣活动商品列表区域的一键全选按钮，用于选中所有已添加商品` |

**C23. 勾选商家协议**  
勾选表单底部「商家自营销协议」复选框。

| unionId | `ClickElementMixed` |
| params.selector.alias | `定位闪购折扣活动表单底部商家自营销协议复选框，用于勾选同意协议` |

**C24. 确认创建**  
点击页面右下角「确认创建」按钮，提交创建折扣活动。

| unionId | `ClickElementMixed` |
| params.selector.alias | `定位闪购折扣活动页面右下角的确认创建按钮，用于提交创建折扣活动` |

---

## 自然语言一段话（可直接粘贴给 Agent）

在闪购测试环境 `https://e.shangou.test.sankuai.com/` 创建折扣活动：打开网页 → 等登录框 8 秒（异常 continue，`probeForIf` 保存本节点）→ 若有则登录（SGtest_yingixao / qwer12345678，勾协议，等 LOAD）→ 通用：侧栏滚 600 → 验「店铺活动」→ 店铺活动 → 立即创建（链式滚动自愈）→ 等 LOAD → 创建折扣活动（链式滚动自愈）→ 结束时间明天 → 门店（北京市/确定）→ 商品（商品名称/手机/苹果手机/搜索/勾第一个/确定，添加商品链式自愈）→ 滚到底 → 请设置 9 折/确定 → 一键全选 → 勾底部协议 → 确认创建 → 延迟 30 秒。Plan：preSteps 2 + ifBranch 5 + postSteps 26（含 2×WaitPageState + Delay），无 Else。异常：有 selector 重试 3 次。

---

## 生成命令

```bash
SKILL_ROOT="${HOME}/.cursor/skills/codex-rpa-workflow-generate"
PLAN="$SKILL_ROOT/reference/examples/shangou-discount-plan.json"

node "$SKILL_ROOT/scripts/preview-plan.mjs" "$PLAN"
node "$SKILL_ROOT/scripts/build-composite-workflow.mjs" "$PLAN"
node "$SKILL_ROOT/scripts/wrap-clipboard.mjs" \
  "${PLAN%.json}.nodes.json" /tmp/shangou.clipboard.txt
bash "$SKILL_ROOT/scripts/repaste-workflow.sh" /tmp/shangou.clipboard.txt
```

## 预期 JSON 顶层结构

| 序号 | type | 说明 |
|------|------|------|
| 1–2 | `rpaNode` | preSteps（OpenUrl、WaitForElementPresent） |
| 3 | `ifNode` | content 含 5 个 rpaNode（ifBranch） |
| 4–27 | `rpaNode` | postSteps（24 步） |

**共计顶层 27 项**（2 + 1 容器 + 24）。无 `elseNode`。
