{
  const APP = "com.tencent.QQMusicMac";
  const wait = ms => new Promise(r => setTimeout(r, ms));
  const parseButtons = text => text.split("\n").map(line => {
    const m = line.match(/^\s*(\d+) (按钮|button) (.+?)\s*$/);
    return m ? { idx: Number(m[1]), title: m[3].trim() } : null;
  }).filter(Boolean);

  const isUpdateDialog = text => /标准窗口 更新|Window: "更新"|QQ音乐for Mac有更新|QQ 音乐 for Mac 有更新|有更新\s*版本:/.test(text || "");

  let clicked = null;
  let result = null;

  for (let attempt = 0; attempt < 4; attempt++) {
    const state = await sky.get_app_state({ app: APP, disableDiff: true });
    const text = state.text || "";
    if (!isUpdateDialog(text)) {
      result = { dismissed: clicked != null, clicked, attempt, reason: "main-window-ready" };
      break;
    }

    const buttons = parseButtons(text);
    const prefer = ["稍后更新", "以后提醒", "忽略此版本更新"];
    let hit = null;
    for (const label of prefer) {
      hit = buttons.find(b => b.title === label || b.title.includes(label));
      if (hit) break;
    }

    if (hit) {
      await sky.click({ app: APP, element_index: hit.idx });
      clicked = hit.title;
      await wait(1500);
      continue;
    }

    await sky.click({ app: APP, x: 520, y: 430 });
    clicked = "coord-fallback";
    await wait(1500);
  }

  if (!result) {
    const finalState = await sky.get_app_state({ app: APP, disableDiff: true });
    const ok = !isUpdateDialog(finalState.text || "");
    result = {
      dismissed: ok,
      clicked,
      reason: ok ? "dialog-closed" : "update-dialog-still-visible",
      window: ((finalState.text || "").match(/Window: "([^"]+)"/) || [])[1] || null
    };
  }

  nodeRepl.write(JSON.stringify(result));
}
