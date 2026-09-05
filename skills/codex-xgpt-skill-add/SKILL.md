---
name: codex-xgpt-skill-add
description: "在 macOS 上通过 cua-router-basic 复刻 Chrome 桌面回放链路，在 xgpt.sankuai.com 的 XGPT/Bots 平台中新建 Skill 对象并进入配置页。"
---

# codex-xgpt-skill-add

用于通过 macOS 桌面回放在 XGPT/Bots 平台创建新的 Skill 对象，并等待进入该 Skill 的配置页。触发词包括：`新建 XGPT Skill`、`在 Bots 创建 Skill`、`创建技能对象`、`xgpt 新建技能`。

## 依赖与执行方式

- 必须依赖并调用 `cua-router-basic`。
- 必须把完整录制链路转换为 `version: 1` 的声明式 JSON 动作时间线。
- 必须通过 `cua-router-basic/scripts/replay.sh` 一次性执行该 JSON。
- 禁止改用脚本直连接口、浏览器自动化框架直改 URL、或用最终配置页 URL 替代页面内点击和表单输入。
- 禁止跳过、合并、重排录制步骤。

执行时生成临时 JSON，例如：

```bash
ROUTE_JSON="$(mktemp -t xgpt-skill-add.XXXXXX.json)"
# 将 version 1 声明式 JSON 写入 $ROUTE_JSON
bash cua-router-basic/scripts/replay.sh "$ROUTE_JSON"
```

如当前仓库中依赖路径不同，应先定位 `cua-router-basic/scripts/replay.sh`，但仍只能调用该 replay 入口一次完成整条回放。

## 输入参数

- `skill_name`：要创建的 Skill 名称。默认值为 `新建技能测试-<date>`，其中 `<date>` 使用当天日期，建议格式 `YYYYMMDD`。
- `skill_description`：Skill 简介。默认值为 `test`。
- `space_id`：空间 ID，默认 `SP57785706e8f74b84`。
- `entry_query`：Chrome 地址栏输入内容，默认 `xgpt`。

名称合法性要求：最终提交的 `skill_name` 不得包含非法空格。如果输入值包含空格，仍按录制链路执行创建尝试；若弹层未关闭，则按录制动作重新聚焦名称输入框并修正为合法名称后再次点击「确 定」。

## 回放质量要求

生成的每一个 action 都必须具备以下三段语义：

1. 操作前刷新 AX tree，并用语义定位目标。
2. 执行单个原子操作。
3. 操作后刷新 AX tree，并校验期望状态。

禁止在声明式 JSON 中使用：

- `elementIndex`
- 坐标点击或坐标偏移
- `observationId`
- 仅依赖 AXGroup 外壳的泛化点击
- BARE target

录制质量基线：Chrome `window.changed` 有完整 AX tree；关键 `mouse.click` target 必须能语义命中按钮「专家」「Skill 技能」「新建」「确 定」，以及名称文本栏、简介文本输入区目标；不能退化为全部 AXGroup 壳层点击。

Web 表单输入推荐使用 paste 策略，并在输入后校验字段值。

## 必须复刻的完整动作时间线

声明式 JSON 必须严格包含以下步骤，不能用摘要替代：

1. 点击 Dock 或激活 Google Chrome。
2. 新建标签页。
3. 在 Chrome 地址栏输入 `entry_query`，默认 `xgpt`。
4. 按 Return，进入 `https://xgpt.sankuai.com/home`。
5. 点击主导航「专家」。
6. 等待进入 `/space/{space_id}/agent/ai-employee`，并出现「AI 专家」「Skill 技能」。
7. 点击左侧「Skill 技能」。
8. 等待进入 `/space/{space_id}/agent/skills`，并出现「搜索...」「技能清单」「新建」。
9. 点击「新建」，打开「创建Skill」弹层。
10. 点击「* Skill名称」输入框。
11. 输入 `skill_name`，录制默认值为 `新建技能测试-date`。
12. 点击「* Skill简介」输入区。
13. 输入 `skill_description`，录制默认值为 `test`。
14. 保留录制中的 Return 键动作，但不得把它作为最终提交创建。
15. 重新定位并点击「确 定」。
16. 若名称里存在非法空格导致仍停留在弹层，按录制动作聚焦名称并修正为合法 `skill_name`。
17. 再点击「确 定」。
18. 等待跳转到 `/space/{space_id}/agent/skills/<new-skill-id>/config` 配置页。

## version 1 JSON 生成规则

生成的 JSON 顶层必须声明版本与变量，例如：

```json
{
  "version": 1,
  "name": "codex-xgpt-skill-add",
  "variables": {
    "skill_name": "新建技能测试-20250101",
    "skill_description": "test",
    "space_id": "SP57785706e8f74b84",
    "entry_query": "xgpt"
  },
  "actions": []
}
```

`actions` 中每一步都要写成声明式三段结构。动作命名可因 `cua-router-basic` 的实际 schema 调整，但语义必须等价：

```json
{
  "name": "click-new-button",
  "before": {
    "refreshAX": true,
    "locate": {
      "role": "button",
      "name": "新建",
      "within": "技能清单"
    }
  },
  "do": {
    "type": "mouse.click",
    "target": {
      "role": "button",
      "name": "新建"
    }
  },
  "after": {
    "refreshAX": true,
    "assert": {
      "visibleText": "创建Skill"
    }
  }
}
```

不要把上例中的字段理解为固定模板；应以当前 `cua-router-basic` 支持的 version 1 schema 为准，但必须保留同等的前置 AX 刷新定位、单步操作、后置 AX 刷新校验。

## 动作细化要求

### 1. 激活 Chrome

- 前置：刷新桌面 AX，定位 Dock 或应用切换中的 `Google Chrome`。
- 操作：点击或激活 `Google Chrome`。
- 后置：刷新 AX，确认前台应用为 Chrome，存在 Chrome 窗口。

### 2. 新建标签页

- 前置：刷新 AX，确认 Chrome 前台。
- 操作：使用录制等价的新建标签页动作，例如 `Command+L` 后 `Command+T`，或语义点击新建标签页按钮；只能执行一个原子动作。
- 后置：刷新 AX，确认地址栏可输入或新标签页已激活。

### 3. 地址栏输入 entry_query

- 前置：刷新 AX，语义定位 Chrome 地址栏。
- 操作：聚焦地址栏并 paste `entry_query`。
- 后置：刷新 AX，校验地址栏值为 `entry_query`。

### 4. Return 进入首页

- 前置：刷新 AX，确认地址栏仍为 `entry_query`。
- 操作：按 Return。
- 后置：刷新 AX，等待并校验 URL 到达 `https://xgpt.sankuai.com/home`，或页面出现 XGPT 首页可识别内容。

### 5. 点击「专家」

- 前置：刷新 AX，定位主导航按钮或链接「专家」。
- 操作：点击「专家」。
- 后置：刷新 AX，等待导航开始并出现可继续判断的页面状态。

### 6. 等待 AI 专家页

- 前置：刷新 AX。
- 操作：等待 URL 匹配 `/space/{space_id}/agent/ai-employee`。
- 后置：刷新 AX，校验页面同时出现「AI 专家」和「Skill 技能」。

### 7. 点击「Skill 技能」

- 前置：刷新 AX，定位左侧导航「Skill 技能」。
- 操作：点击「Skill 技能」。
- 后置：刷新 AX，等待页面切换。

### 8. 等待技能清单页

- 前置：刷新 AX。
- 操作：等待 URL 匹配 `/space/{space_id}/agent/skills`。
- 后置：刷新 AX，校验出现「搜索...」「技能清单」「新建」。

### 9. 点击「新建」

- 前置：刷新 AX，定位按钮「新建」。
- 操作：点击「新建」。
- 后置：刷新 AX，校验出现「创建Skill」弹层。

### 10. 点击「* Skill名称」输入框

- 前置：刷新 AX，在「创建Skill」弹层内定位标签「* Skill名称」对应的文本输入框。
- 操作：点击名称输入框。
- 后置：刷新 AX，校验该输入框获得焦点。

### 11. 输入 skill_name

- 前置：刷新 AX，确认焦点在「* Skill名称」输入框。
- 操作：paste `skill_name`。
- 后置：刷新 AX，校验字段值等于 `skill_name`。

### 12. 点击「* Skill简介」输入区

- 前置：刷新 AX，在「创建Skill」弹层内定位标签「* Skill简介」对应的文本输入区。
- 操作：点击简介输入区。
- 后置：刷新 AX，校验该输入区获得焦点。

### 13. 输入 skill_description

- 前置：刷新 AX，确认焦点在「* Skill简介」输入区。
- 操作：paste `skill_description`。
- 后置：刷新 AX，校验字段值等于 `skill_description`。

### 14. 保留 Return 键动作

- 前置：刷新 AX，确认仍在「创建Skill」弹层内。
- 操作：按 Return。
- 后置：刷新 AX，校验仍可定位弹层或表单区域；不得把这个 Return 视为最终提交成功条件。

### 15. 点击「确 定」

- 前置：刷新 AX，在「创建Skill」弹层内重新定位按钮「确 定」。
- 操作：点击「确 定」。
- 后置：刷新 AX，判断是否跳转或是否仍停留弹层；若弹层消失则进入最终等待步骤，若仍存在且名称校验失败则进入修正步骤。

### 16. 非法空格修正分支

仅当点击「确 定」后仍停留在「创建Skill」弹层，且名称因为非法空格等原因未通过校验时执行：

- 前置：刷新 AX，重新定位「* Skill名称」输入框。
- 操作：聚焦名称输入框，清空原值，paste 合法 `skill_name`。
- 后置：刷新 AX，校验名称字段值为合法 `skill_name`，且不含非法空格。

合法化策略应保持名称含义，优先删除首尾空格并将内部空白替换为 `-` 或直接移除，确保最终值符合平台限制。

### 17. 再次点击「确 定」

- 前置：刷新 AX，在弹层内重新定位按钮「确 定」。
- 操作：点击「确 定」。
- 后置：刷新 AX，确认弹层关闭或页面开始跳转。

### 18. 等待配置页

- 前置：刷新 AX。
- 操作：等待 URL 匹配 `/space/{space_id}/agent/skills/<new-skill-id>/config`，其中 `<new-skill-id>` 为平台生成的任意非空路径段。
- 后置：刷新 AX，校验已经进入 Skill 配置页，并尽可能确认页面显示当前 `skill_name` 或配置相关区域。

## 失败处理

- 如果未登录、无权限或空间不存在，应停止回放并报告当前 AX 可见错误文本，不得尝试绕过登录或权限控制。
- 如果语义定位不到目标，必须重新刷新 AX 并重试有限次数；仍失败时输出缺失的目标名称与当前 URL。
- 如果最终没有进入 `/space/{space_id}/agent/skills/<new-skill-id>/config`，应报告最后一次 URL、弹层是否仍存在、名称字段值和简介字段值。

## 成功判定

只有同时满足以下条件才算成功：

- 已按录制链路执行 Chrome 激活、新标签页、地址栏输入、Return、页面导航点击、表单输入、Return 保留动作、确定按钮提交。
- 最终 URL 匹配 `/space/{space_id}/agent/skills/<new-skill-id>/config`。
- 未使用坐标、索引、observationId 或最终 URL 直跳替代页面操作。
- 表单中的 Skill 名称和简介已经按输入参数提交。
