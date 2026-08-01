# 技能默认策略：从运行时键盘输入切换到预采集+平台捕获

**description**: 原技能默认在运行时配置弹框里用键盘模拟输入 XPath（C1 方式），这在 AntD Select 环境下必然阻断。教训是：含元素选择器的任意指令（含断言/等待类）都应**强制前置**批量采集，并优先用平台捕获（方式 B）而非键盘模拟。

## 原策略痛点

- 「批量采集」定位为可选/推荐，仅针对 FillText/点击指令
- 方式 C1（粘贴+为定位器）作为默认写入路径
- 对 AntD Select 组件没有独立处理路径

## 改进后策略

1. **强制前置**：含元素选择器的任意指令（≥10 类）→ 配表前必先批量采集 XPath
2. **优先级**：方式 B（VNC 捕获）> 方式 C1（粘贴+为定位器）> 方式 D（React setter）
3. **AntD Select 识别信号**：保存后「该字段是必填字段」红字持续 → 立即转方式 D

## 关键变更文件

- `SKILL.md`：章节标题 & 触发条件扩展、写入策略优先级
- `reference/element-selector.md`：方式 B 提升默认、方式 D 新增
- `reference/ax-verify.md`：AntD Select 阻断信号决策表

## 可复用模式

任何平台组件若不响应合成键盘事件（AntD Select、Combobox 等），都可用 `nativeInputValueSetter + dispatchEvent` 方案；优先检查平台是否提供非键盘写入路径（如「捕获」按钮）。
