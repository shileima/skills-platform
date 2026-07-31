# 点击元素（推荐）

- **指令标识**：`ClickElementMixed`
- **指令类型**：网页指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/clickelementmixed/
- **平台搜索名称**：`点击` / `点击元素`
- **说明**：点击网页中的按钮、链接或者其他任何元素，支持智能重试和强制点击
- **必填输入参数**：`元素选择器`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 元素选择器 | String | 是 | - | 用于定位的页面元素的选择器，选择器不能为空，支持从元素库选择元素或手动填写XPath等定位器值 |
| 鼠标键 | Enum | 否 | LEFT | 指定要使用的鼠标按键类型，支持 LEFT （左键，默认）、 RIGHT （右键）、 MIDDLE （中键滚轮） |
| 点击次数 | Integer | 否 | 1 | 指定点击次数，默认为 1 次。设置为 2 实现双击效果，符合DOM UIEvent.detail规范 |
| 辅助按键 | List<Enum> | 否 | - | 点击时同时按下的键盘辅助键，支持 ALT 、 CONTROL 、 META 、 SHIFT 。用于实现Ctrl+点击、Shift+点击等组合操作 |
| 横坐标 | Double | 否 | - | 点击位置的横坐标，相对于元素左上角的偏移量 |
| 纵坐标 | Double | 否 | - | 点击位置的纵坐标，相对于元素左上角的偏移量 |
| iframe页面定位器 | String | 否 | - | iframe的XPath，非必填，如果目标元素在iframe中则需要填写，例如：//html/iframe |
| 定位超时 | Double | 否 | 5000 | 元素定位的最大等待时间，单位毫秒，默认值 5000ms 。设置为 0 表示不等待 |

## 配置要点

- **必填**：`元素选择器`（带红色 `*`，未填时输入框红色边框）
- 粘贴 XPath → **等 1s** → 点「以 //xxx 为定位器」→ 若下拉「未找到匹配结果」则点右侧 close icon
- **保存前**确认选择器无红框，再点弹框右下角「保存」

## XML 示例

```xml
<ClickElementMixed  selector="//*[@id='__next']/div[1]/nav/ul/li[2]/a/span/span[1]"  clickOptions="{'button':'LEFT','clickCount':1}"  findElementOptions="{'timeout':5000}"/>
```

## 注意事项

- 智能重试机制，提高点击成功率
- 自动处理弹窗
- 支持更多的点击方式和配置选项
- LEFT：左键（默认）
- RIGHT：右键
