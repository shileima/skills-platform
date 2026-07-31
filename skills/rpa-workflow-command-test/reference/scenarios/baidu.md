# 场景 A：百度搜索

**目标**：打开百度 → 搜索框输入 `baidu` → 点击搜索按钮 →（可选）验证搜索结果页

**工作流命名建议**：`百度搜索测试-YYYYMMDD`（或用户指定名称）

## 元素定位器缓存

| 页面 | JSON 缓存 | 摘要 |
|------|----------|------|
| 百度首页 | [baidu.elements.json](../locators/baidu.elements.json) | [baidu.md](../locators/baidu.md) |
| 百度搜索结果页 | [baidu-search.elements.json](../locators/baidu-search.elements.json) | [baidu-search.md](../locators/baidu-search.md) |

更新命令：

```bash
bash scripts/update-locators.sh all-baidu    # 首页 + 搜索结果页
```

## 云浏览器默认 XPath（已实测）

bots 云浏览器打开 `https://www.baidu.com/` 时为**智能输入版**，第 2、3 步直接用：

| 元素 | XPath |
|------|-------|
| 搜索框 | `//*[@id="chat-textarea"]` |
| **百度一下**（搜索按钮） | `//*[@id="chat-submit-button"]` |

> 输入框与按钮必须同一 UI 版本配对；勿混用 `#kw` 与 `#chat-submit-button`。

## ⚠️ 其他环境：先探测再填 XPath

百度在 **`https://www.baidu.com/`** 同一 URL 下存在 **两种 UI**（A/B / Cookie / 内网环境差异）：

| UI 版本 | 搜索框 XPath | 搜索按钮 XPath |
|--------|-------------|---------------|
| 经典版 | `//*[@id="kw"]` | `//*[@id="su"]` |
| 智能输入版 | `//*[@id="chat-textarea"]` | `//*[@id="chat-submit-button"]` |

> **云浏览器（bots 调试）常见为智能输入版**，即使 URL 仍是 `https://www.baidu.com/` 且无 `/s?`。
> 本地 Playwright 采集可能得到经典版。**以云浏览器实测为准**，见 `element-selector.md` §百度搜索框探测。

### 配置第 2、3 步前必做（云浏览器 DevTools）

1. 调试运行「打开网页」后，在云浏览器按 F12 打开 Console
2. 执行探测（复制整行）：

```javascript
JSON.stringify(['kw','chat-textarea'].map(id=>{const el=document.getElementById(id);if(!el)return{id,present:false};const r=el.getBoundingClientRect();const vis=r.width>0&&r.height>0&&getComputedStyle(el).display!=='none';return{id,present:true,visible:vis,tag:el.tagName,w:Math.round(r.width)};}))
```

3. 取 **`visible:true`** 的那一组 id 填 XPath：
   - `chat-textarea` 可见 → 输入框 `//*[@id="chat-textarea"]`，按钮 `//*[@id="chat-submit-button"]`
   - `kw` 可见 → 输入框 `//*[@id="kw"]`，按钮 `//*[@id="su"]`

4. 全量抓 AX Tree 确认（`ax-verify.md`）后再填表保存

## 指令节点（基础三步骤）

| 序号 | 指令 | reference | 关键配置 |
|------|------|-----------|---------|
| 1 | 打开网页 | [openurl.md](../commands/openurl.md) | 网址：`https://www.baidu.com`（**pbcopy 粘贴**，禁止 type_text，见 [url-input.md](../url-input.md)） |
| 2 | 输入文本 | [filltext.md](../commands/filltext.md) | `//*[@id="chat-textarea"]`（云浏览器） |
| 3 | 点击元素（推荐） | [clickelementmixed.md](../commands/clickelementmixed.md) | `//*[@id="chat-submit-button"]`（百度一下） |

若工作流需在**搜索结果页**继续操作，追加指令；结果页通常已是 `chat-textarea`，见 [baidu-search.md](../locators/baidu-search.md)。

## 执行步骤

按 [test-workflow.md](../test-workflow.md) 标准流程：

1. rpa.sankuai.com **首页** → 点「工作流」→ 新建**空**编排工作流
2. **追加式**按序添加 3 条指令（详见 `platform-ops.md` §2.3）：
   - **第 1 条**：选中「开始节点」→ Enter 创建空行 → `/` → 搜「打开网页」→ 插入 → 配置保存
   - **第 2 条**：选中「打开网页」→ **Enter** 创建空行 → `/` → 搜「输入文本」→ 插入 → **校验「打开网页」在其上方** → 配置保存
   - **第 3 条**：选中「输入文本」→ **Enter** 创建空行 → `/` → 搜「点击」→ 插入 → 配置保存
3. **批量采集 XPath**（若 locators 缓存不可用或与云浏览器不符）：`element-selector.md` §批量采集 → 新建 Tab 探测 variant → 再配第 2、3 步
4. 逐条配置表单 → **保存前确认必填项无红框** → 保存
5. **调试前场景顺序终检**（`test-workflow.md` §调试前场景顺序终检）：对照本文件「指令节点」表，确认 canvas 为 `开始 → 打开网页 → 输入文本 → 点击 → 结束`
6. 完整调试 → 运行 → 查**聊天区日志** + **编排区红色 icon**
7. 顺序错误时：**选中错位节点 → 右击剪切 → 选中锚点行 → Enter 创建空行 → 粘贴**（§2.3a）；其他修复见 `debug.md`，直到全部 ✅
