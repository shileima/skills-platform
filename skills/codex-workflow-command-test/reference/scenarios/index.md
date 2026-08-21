# 测试场景索引

用户指定场景时读取对应场景文件。**未指定测试场景或测试指令时，禁止询问用户**，直接默认 **B站场景**（Read [bilibili.md](bilibili.md)）：**打开网页 → 输入文本 → 点击元素 → 刷新网页**，立即开始执行。

> 所有场景均遵循 [test-workflow.md](../test-workflow.md)：**rpa 首页 → 点工作流 → 新建空工作流 → 编排区按序加指令 → 配表单保存 → 调试运行 → 查聊天区日志与红色 icon → 修复**。

## 可用场景

| 场景 | 触发关键词 | reference 文件 |
|------|-----------|---------------|
| A：百度搜索 | 百度、baidu | [baidu.md](baidu.md) |
| B：Bilibili 搜索 | bilibili、B站、哔哩哔哩 | [bilibili.md](bilibili.md) |
| **C：搜狗搜索四步** | sogou、搜狗 | [sogou.md](sogou.md) |
| **D：百度首页 9 条网页断言批量测试** | 网页断言、验证元素、断言测试、verify 全量、断言场景 | [baidu-assertions.md](baidu-assertions.md) |
| **E：上传文件指令测试**（`UploadFileFromS3`） | 上传文件、UploadFileFromS3、图片上传组件测试、`input[type=file]`、附件上传测试 | [upload-file.md](upload-file.md) |
| **F：循环遍历元素·小红书首页标题**（`LoopElements`） | 循环遍历元素、LoopElements、小红书循环、遍历页面元素、批量抓取标题、`@{toolId.index}`、outputList 测试 | [loop-elements-xhs.md](loop-elements-xhs.md) |
| **G：网页操作基础·多标签导航**（WF3） | 网页操作基础、刷新后退前进、切换标签、关闭标签、WaitPageState、删除 Cookie、关闭浏览器 | [web-navigation-basic.md](web-navigation-basic.md) |

> **G 场景站点**：`https://www.baidu.com` → `https://www.sogou.com` → `https://www.sina.com.cn`。**禁止** `example.com` / `example.org`。

## 默认场景（无用户输入时）

| 项目 | 值 |
|------|-----|
| 场景 | B：Bilibili（[bilibili.md](bilibili.md)） |
| 指令链 | 打开网页 → 输入文本 → 点击元素 → 刷新网页 |
| 行为 | **直接开始**，不向用户索要场景或指令列表 |

## 通用执行顺序（不可打乱）

```
打开网页 → （新建 Tab 批量采集 XPath）→ 输入文本 → 点击元素 → （刷新网页，默认 B 站场景含此步）→ 调试运行
```

**插入约束**（`insert-command.md` §Enter 空行规则）：**首条**选中开始节点 → Enter；**向后追加**选中锚点指令 → Enter；**向前插入**选中目标上一条 → Enter。禁止从结束节点上方起建。插入后校验顺序依赖（如「打开网页」在「输入文本」之前）。

**调试前终检**：全部保存后、点「调试」前，必须对照场景「指令节点」表做整链顺序终检（`test-workflow.md` §调试前场景顺序终检）。终检未通过禁止调试。**终检通过且无报错 → 直接调试运行，禁止询问用户**（`test-workflow.md` §无报错即调试门控）。

## 扩展新场景

1. 在 `reference/scenarios/` 下新建 `<场景名>.md`
2. 更新本文件的「可用场景」表格
3. 在 SKILL.md 的 description 中补充触发关键词（可选）

每个场景文件应包含：
- 目标描述与工作流命名建议
- 指令节点表（引用 `reference/commands/` 下对应文件）
- 元素选择器（实测值或采集要求）
- 逐步执行清单
