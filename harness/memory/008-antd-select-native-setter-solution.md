# AntD Select 输入阻断的 nativeInputValueSetter 方案

**description**: AntD Select/Combobox 组件的输入框不响应 sky 键盘模拟事件（pbcopy+cmd+v、type_text），导致保存时出现「该字段是必填字段」红字。解决方案是通过 DevTools Console 调用 React 内部的 `nativeInputValueSetter`（`Object.getOwnPropertyDescriptor(HTMLInputElement.prototype,'value').set`）并派发原生 `input`/`change` 事件强制触发 React onChange。

## 问题症状

- 在 bots.sankuai.com 配置断言/等待/操作指令的「元素选择器」字段时
- 粘贴 XPath（cmd+v）后 value 显示但保存始终红字「该字段是必填字段」
- `type_text` 同样无效；`[`/`]`/`"` 等 Shift 修饰符字符会被丢弃

## 根因

AntD Select 的 `rc-select` 只监听 `nativeInputValueSetter` 派发的原生 `input`/`change` 事件，合成键盘事件不触发 `onChange`，React state 不更新，平台校验始终认为字段为空。

## 解决方案（方式 D）

### 变体一：activeElement

```javascript
(function(xpath) {
  const el = document.activeElement;
  const proto = el.tagName === 'TEXTAREA'
    ? HTMLTextAreaElement.prototype : HTMLInputElement.prototype;
  const desc = Object.getOwnPropertyDescriptor(proto, 'value');
  desc.set.call(el, xpath);
  el.dispatchEvent(new Event('input', { bubbles: true }));
  el.dispatchEvent(new Event('change', { bubbles: true }));
})('//*[@id="YOUR_XPATH_HERE"]');
```

### 变体二：按 AntD class 精确定位

```javascript
(function(xpath) {
  const el = Array.from(
    document.querySelectorAll('[class*="ant-select-selection-search-input"]')
  ).filter(e => e.getBoundingClientRect().width > 0).pop();
  const desc = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value');
  desc.set.call(el, xpath);
  el.dispatchEvent(new Event('input', { bubbles: true }));
  el.dispatchEvent(new Event('change', { bubbles: true }));
})('//*[@id="YOUR_XPATH_HERE"]');
```

## 策略位置

- `reference/element-selector.md` §方式 D
- 优先级：方式 B（平台捕获）> 方式 C1（粘贴+为定位器）> 方式 D（本方案）

## 注意事项

- 依赖 React 内部约定，未来 AntD/React 版本变更可能失效
- 若 `desc.set is undefined`：目标不是标准 input/textarea，检查 `document.activeElement`
- 主推方式 B（云浏览器 VNC 捕获）；方式 D 作为最后兜底
