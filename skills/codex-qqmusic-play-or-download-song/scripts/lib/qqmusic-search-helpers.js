  const qqmParseIndex = (text, pattern) => {
    const re = new RegExp(`\\n\\s*(\\d+) ${pattern}`);
    const m = text.match(re);
    return m ? Number(m[1]) : null;
  };

  const qqmDismissUpdateIfPresent = async app => {
    const wait = ms => new Promise(r => setTimeout(r, ms));
    const text = (await sky.get_app_state({ app, disableDiff: true })).text || "";
    if (!/标准窗口 更新|Window: "更新"|QQ音乐for Mac有更新|QQ音乐 for Mac有更新/.test(text)) {
      return;
    }
    const buttons = text.split("\n").map(line => {
      const m = line.match(/^\s*(\d+) (按钮|button) (.+?)\s*$/);
      return m ? { idx: Number(m[1]), title: m[3].trim() } : null;
    }).filter(Boolean);
    const prefer = ["以后提醒", "稍后更新", "忽略此版本更新"];
    const hit = prefer.map(label => buttons.find(b => b.title.includes(label))).find(Boolean);
    if (hit) {
      await sky.click({ app, element_index: hit.idx });
      await wait(1500);
    }
  };

  const qqmFindGlobalSearchInputIdx = text => {
    if (!/按钮 取消搜索|面板 搜索/.test(text)) return null;
    for (const line of text.split("\n")) {
      const m = line.match(/^\s*(\d+) 文本栏 \(settable, string\).*搜索/);
      if (m) return Number(m[1]);
    }
    return null;
  };

  const qqmOpenedSearch = text => /按钮 取消搜索|面板 搜索|搜索历史/.test(text || "");

  // 顶栏搜索外层 AX「文本框 搜索」不可 set；idx 点击会落到错误中心。
  // 使用窗口相对中心坐标点击，再 Command+V；AX 常常不回显已输入的中文。
  const qqmFillSearchBox = async (app, query, searchX, searchY) => {
    const wait = ms => new Promise(r => setTimeout(r, ms));
    await qqmDismissUpdateIfPresent(app);
    let state = await sky.get_app_state({ app, disableDiff: true });
    const x = Number.isFinite(Number(searchX)) ? Number(searchX) : 438;
    const y = Number.isFinite(Number(searchY)) ? Number(searchY) : 40;
    await sky.click({ app, x, y });
    await wait(700);
    await sky.press_key({ app, key: "Command+a" });
    await wait(100);
    await sky.press_key({ app, key: "Delete" });
    await wait(100);
    await sky.press_key({ app, key: "Command+v" });
    await wait(800);
    state = await sky.get_app_state({ app, disableDiff: true });
    const inputIdx = qqmFindGlobalSearchInputIdx(state.text);
    if (inputIdx && !state.text.includes(query)) {
      await sky.set_value({ app, element_index: inputIdx, value: query });
      await wait(600);
      state = await sky.get_app_state({ app, disableDiff: true });
    }
    return state;
  };
