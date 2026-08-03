# qqmusic-play-song — QQ 音乐固化播放技能

在 QQ 音乐桌面客户端 (`com.tencent.QQMusicMac`) 搜索并播放指定歌曲；也支持在已打开的歌手详情页下载热门歌曲前 5 首。播放歌曲流程已固化，元素定位顺序为 AX Tree → macOS Vision OCR → 固定坐标扫描。

## 依赖

参照 `cua-router-basic` 技能的依赖说明和启动方式。sky bootstrap 代码和辅助函数（findIdx 等）见 `cua-router-basic` 技能。

## 何时激活

用户说：
- "QQ 音乐播放 X"
- "在 QQ 音乐搜 X 并播放"
- "用 QQ 音乐听 X"
- "QQ 音乐下载某歌手热门歌曲前 5 首"
- "进入歌手页面，下载前 5 首歌"
- 或提供任何 `<歌名> <歌手>` 组合、明确指向 QQ 音乐客户端

## 一键执行：播放歌曲

```bash
bash "./scripts/play-song.sh" "<歌名>" "[歌手]"
```

示例：

```bash
bash ./scripts/play-song.sh "晴天" "周杰伦"
```

脚本会：

1. 启动 `cua-router` 守护进程（`daemon.sh start`，已在跳过）
2. `open -b com.tencent.QQMusicMac` 启动 QQ 音乐并等待窗口
3. `osascript` activate 到前台
4. **`osascript` 写剪贴板**（`pbcopy` 在某些 shell 会静默失效）
5. **坐标点击搜索栏 (438, 40)**（AX 里 `文本框 搜索` 不支持 `set_value`；用 idx click 不能真正聚焦）
6. `Command+a` → `Delete` 清空 → `Command+v` 粘贴中文
7. `Return` 提交搜索，等待进入完整搜索结果页
8. 定位并播放结果：优先 AX Tree 找歌曲元素；AX 缺失时用 macOS Vision OCR 定位歌曲名中心坐标；OCR 失败再按候选坐标扫描
9. 校验：读播放控制栏 `歌曲名：X - 歌手名：Y`，输出到 stdout

成功时最后一行输出 JSON：

```json
{"ok":true,"expected":"晴天 - 周杰伦","nowPlaying":"25 文本 歌曲名：晴天 - 歌手名：周杰伦","successAttempt":"ocr:晴天@345,393","successX":345,"successY":393,"strategy":"ocr","screenshot":"file:///.../QQ音乐 Screenshot ....jpeg"}
```

## 一键执行：下载歌手页热门歌曲前 5 首

前置条件：无需手动进入歌手页。脚本会先只搜索歌手名（例如 `张雨生`，不要拼 `歌手`），再点击搜索结果里的「歌手:张雨生」进入个人页；随后下载热门歌曲前 5 首。下载使用 QQ 音乐客户端官方入口，选择「标准品质」；不绕过会员、版权或客户端限制。

```bash
bash "./scripts/download-singer-top5.sh" "<歌手名>"
```

示例：

```bash
bash ./scripts/download-singer-top5.sh "毛阿敏"
```

脚本会：

1. 启动并激活 QQ 音乐
2. 如果当前不在目标歌手页，**只搜索歌手名**（例如 `张雨生`，不要带 `歌手`）
3. 在搜索结果中点击「歌手:歌手名」进入个人页
4. 校验当前页包含目标歌手名和「热门歌曲」
5. 依次处理热门歌曲前 5 首
6. **先点击歌曲名称选中 / hover 行**，否则下载 icon 可能不可点击
7. 点击该行 `下载` link
8. 在音质弹窗选择 `标准品质`
9. 进入「本地」页校验 `已下载歌曲` / `正在下载歌曲`

成功时最后一行输出 JSON：

```json
{"ok":true,"singer":"毛阿敏","downloadedLine":"94 按钮 已下载歌曲 5首歌曲","downloadingLine":"95 按钮 正在下载歌曲 0首歌曲"}
```


## 关键坐标与常量（QQMianWindow 默认尺寸 927×768）

| 位置 | 坐标 / AX | 说明 |
|------|-----------|------|
| 搜索栏输入区 | `(438, 40)` | 顶栏中间的"搜索音乐"输入框 |
| 歌手搜索关键词 | `<歌手名>` | 只搜 `张雨生`，不要搜 `张雨生 歌手` |
| 搜索结果歌手入口 | `(300,190)` 等候选区 | 点击「歌手:张雨生」进入个人页，脚本会尝试多个候选坐标 |
| 搜索结果第一首 | 动态解析「歌名/歌手」标题下第一条结果的歌曲名称或图标 | 播放歌曲时优先点击，避免点击到搜索建议或其它区域 |
| 搜索结果首行兜底 | `(300, 355)` | AX 未命中时双击首行歌名区触发播放 |
| 歌手页前 5 首 | 动态解析「热门歌曲」区内每行首个歌名文本 + `link 下载` | 不固定 AX 下标，不同歌手页面会变化 |
| 音质弹窗 | 动态查找 `link 标准品质` | 不硬编码 idx，弹窗 idx 会变化 |

窗口尺寸或缩放变化后坐标需重新校准，可通过 `sky.get_app_state({app:"com.tencent.QQMusicMac", disableDiff:true})` 的 `screenshot.url` 抓图后目测调整。

## 避坑清单（本技能固化的原因）

| 陷阱 | 现象 | 解决 |
|------|------|------|
| 对搜索框调用 `set_value` | 报 `Cannot set a value for an element that is not settable` | 只能坐标点击 + 粘贴 |
| `sky.click({element_index:234})` 定位搜索框 | click 成功但输入框未真正获得焦点，后续按键无效果 | 用坐标 `(438, 40)` |
| `printf ... \| pbcopy` 写中文剪贴板 | 某些 sandbox / 会话下写入后 `pbpaste` 为空 | 改用 `osascript -e 'set the clipboard to "..."'` |
| `type_text("晴天 周杰伦")` | 中文 IME 组合异常，可能漏字 | 只走剪贴板 `Command+v` |
| 未 `activate` 就发 `Command+v` | 组合键落到别的前台 App | 每次执行前 `osascript activate` |
| 搜索 `张雨生 歌手` | 结果容易停在搜索浮层或歌曲结果，不进歌手页 | 只搜索 `张雨生`，再点击「歌手:张雨生」 |
| 歌手页直接点 `下载` AX link | 没反应或不弹音质窗口 | 必须先点击同一行歌曲名称，让行进入选中 / hover 状态 |
| 歌手页固定写死前 5 首 AX 下标 | 不同歌手页面下标会变化，可能点错专辑名或其它行 | 动态解析「热门歌曲」区内每行首个歌名文本和 `link 下载` |
| 音质弹窗 `标准品质` idx 固定写死 | 不同歌曲弹窗 idx 可能变（如 324 / 345） | 每次弹窗后动态查找 `link 标准品质` |

## 操作规范

遵循 `cua-router-basic` 技能的标准操作规范（`nodeRepl.write` 输出、`disableDiff:true`、`click_count` snake_case、块作用域等）。

## 扩展方向（未固化，用到时再补）

- 参数化「双击第 N 首」：改 `y` 坐标（首行 355，每行约 50px）
- 播放/暂停/下一首：AX `按钮 播放` / `按钮 上一首` / `按钮 下一首`（首页取到的 idx 分别是 237 / 236 / 238，但每次布局不同建议动态 findIdx）
- 收藏当前歌：`按钮 从我喜欢删除` 或 对应"添加到我喜欢"按钮
