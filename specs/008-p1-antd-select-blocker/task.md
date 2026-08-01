# 008-p1-antd-select-blocker · TASK

> 状态标记：`TODO` / `IN_PROGRESS` / `DONE` / `BLOCKED`
> Owner：`developer` subagent（除非另注）

## T1. 通用采集器改造 · `scripts/collect-locators.py`
- 状态：TODO
- Owner：developer
- 内容：
  - 新增 `select_quick_elements()`：挑 input / textarea / button / role=search / aria-label/placeholder 含"搜索"的元素，最多各 5 条。
  - `render_markdown()` 分支：非 baidu/bilibili 走通用快捷 XPath 渲染。
  - 支持 `--user-data-dir <path>`（可选，用于登录态站点）。
  - URL 加载失败时把 `warning` 字段写入 JSON 和 Markdown。
- 验收：手工跑 `python3 scripts/collect-locators.py --site example --url https://example.com`，产出 JSON + Markdown，快捷 XPath 章节列出至少一条 input 或 button 且以 `//` 开头。

## T2. shell 入口 · `scripts/update-locators.sh`
- 状态：TODO
- Owner：developer
- 内容：
  - 兜底分支加入 URL 缺失校验，报错文案："Usage: bash update-locators.sh <slug> <url>"。
  - 帮助文本补 "任意站点：bash scripts/update-locators.sh <slug> <url>" 一行。
- 验收：`bash scripts/update-locators.sh unknown` exit 1 且给出明确 usage；`bash scripts/update-locators.sh example https://example.com` 正常出结果。

## T3. `reference/element-selector.md` 新增方式 D + 顺序调整
- 状态：TODO
- Owner：developer
- 内容：
  - 顶部"批量采集"改为"批量采集（新建 Tab · 强制前置）"；触发条件扩展为"含元素选择器的**任意**指令，含断言类"。
  - 新增章节"方式 D：DevTools 注入 React nativeInputValueSetter（AntD Select 兜底）"，附完整 JS 脚本、触发步骤、AX 验证信号。
  - 方式 B 从备选提升为"**默认策略**"；开头明确"AntD Select/Combobox 环境下优先用平台捕获"。
  - 方式 C1 添加提示："AntD Select 环境下 press_key(cmd+v) 不会触发 onChange，若保存红字持续 → 立即转方式 D"。
- 验收：文件内容完整；方式 D 脚本可复制粘贴执行；路径优先级 B > C1 > D 明确。

## T4. `reference/ax-verify.md` 判定分支扩展
- 状态：TODO
- Owner：developer
- 内容：
  - 在 Step B 后加入"AntD Select 阻断信号"决策表。
  - 更新"常见动作 → 成功信号"表：新增"AntD Select 输入"一行；成功信号=AX 中"该字段是必填字段"消失 且 出现"为定位器"下拉。
  - 新增 helper 示例：`axSelectStillRequired(lines) => lines.some(l => l.includes('该字段是必填字段'))`。
- 验收：文档新章节完整、判定表清晰、helper 可复用。

## T5. `SKILL.md` 顶层策略切换
- 状态：TODO
- Owner：developer
- 内容：
  - 修改"元素 XPath 批量采集"章节：触发条件扩展为"含元素选择器的任意 UI 指令（含断言/等待类）"；写入策略优先级 B > C1 > D。
  - "边界"章节补一行"AntD Select 输入模拟键盘失败 → 用方式 D DevTools setter"。
- 验收：SKILL.md 顶层信息完整、指向新方式 D。

## T6. 场景文件补充
- 状态：TODO
- Owner：developer
- 内容：
  - `reference/scenarios/baidu.md`、`bilibili.md` 补"元素选择器写入策略"一节，指向 element-selector.md 方式 B/C1/D。
- 验收：场景文件包含新章节，链接可跳转。

## T7. E2E 补充 · `scripts/verify/`
- 状态：TODO
- Owner：tester（在 developer 完成 T1–T6 后启动）
- 内容：
  - 项目根新建 `scripts/verify/` 目录。
  - 新增 `scripts/verify/verify_collect_locators.sh`：
    1. 调 `bash skills/rpa-workflow-command-test/scripts/update-locators.sh __e2e_example https://example.com`
    2. 断言 `skills/rpa-workflow-command-test/reference/locators/__e2e_example.elements.json` 存在，`elementCount > 0`，随机抽 3 条 elements[i].xpath 都以 `//` 开头
    3. 断言 `skills/rpa-workflow-command-test/reference/locators/__e2e_example.md` 中含 "快捷 XPath" 章节
    4. cleanup：删除 `__e2e_example.*` 两个文件
  - 幂等、可重复执行。
- 验收：`bash scripts/verify/verify_collect_locators.sh` 退出码 0。

## T8. `skilldev validate` 与构建校验
- 状态：TODO
- Owner：reviewer（作为 review gate 的一部分）
- 内容：
  - 跑 `node bin/skilldev.mjs validate` 全绿。
  - 跑 `node bin/skilldev.mjs build rpa-workflow-command-test --target all`，确保新增/修改文件同步到 dist/。
- 验收：validate & build 全部无错。

## T9. 知识沉淀（Step 6）
- 状态：TODO
- Owner：recordor + orchestrator
- 内容：
  - `docs/` 中补一段"AntD Select 输入阻断的处理策略"（若 docs 结构允许）。
  - `harness/memory/008-antd-select-blocker-lesson.md`：沉淀"React 合成事件 vs sky 键盘模拟"教训。
- 验收：文件已创建，`harness/memory/memory_map.md`（若存在或需建）已更新。
