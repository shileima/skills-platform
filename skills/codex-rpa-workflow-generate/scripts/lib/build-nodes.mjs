#!/usr/bin/env node
/** 构建 TipTap 可粘贴的 rpaNode JSON 数组 */

import { fetchCommandList, resolveCommandMeta } from "./fetch-commands.mjs";
import { generateId, generateWorkflowElementId } from "./generate-id.mjs";

/** 一期支持的 Web 原子指令 */
export const ALLOWED_UNION_IDS = new Set([
  "OpenUrl",
  "NavigateToUrl",
  "FillText",
  "ClickElementMixed",
  "ReloadPage",
  "GetText",
  "GetUrl",
  "GetWindowTitle",
  "GetWindowIndex",
  "VerifyElementPresent",
  "VerifyElementVisible",
  "VerifyElementNotPresent",
  "VerifyElementNotVisible",
  "VerifyTextPresent",
  "VerifyTextNotPresent",
  "WaitForElementPresent",
  "WaitForElementNotPresent",
  "WaitPageState",
  "TakeScreenshot",
  "SendKeys",
  "ScrollToElement",
  "ScrollToPosition",
  "MouseOver",
  "BackPage",
  "ForwardPage",
  "Delay",
]);

const LLM_MODEL = "Doubao-Seed-2.0-pro";

/** 不入库 LLM 元素选择器（elementSourceType: elementAdd） */
export function buildSelectorId(alias) {
  const workflowElementId = generateWorkflowElementId();
  const elementJson = {
    alias,
    elementType: "web",
    locateModeJsons: [
      {
        editable: true,
        enable: true,
        frameSelector: "",
        locateMode: "LLM",
        locateModeValue: alias,
        modelName: LLM_MODEL,
      },
    ],
    workflowElementId,
  };
  const jsonStr = JSON.stringify(elementJson);
  return {
    workflowElementId,
    label: alias,
    locateModeJsons: [
      {
        enable: true,
        locateModeValue: jsonStr,
        locateMode: "LLM",
      },
    ],
    isCustomXpathOption: false,
    pageName: "",
    screenshotUrl: "",
    highlightScreenshotUrl: "",
    alias,
    elementSourceType: "elementAdd",
    selector: jsonStr,
    selectorType: "element",
    locator: { locator: jsonStr },
    element: jsonStr,
  };
}

function defaultFailOptions() {
  return { failureHandling: "stop" };
}

function findElementOptions(params = {}) {
  return { timeout: String(params.findTimeout ?? params.timeout ?? "10000") };
}

function renderToolDesc(showDesc, formData) {
  let desc = showDesc || "";
  for (const [key, val] of Object.entries(formData)) {
    if (key === "selectorId" && val && typeof val === "object") {
      desc = desc.replace(/\$\{selectorId\}/g, val.alias || val.label || "元素");
      desc = desc.replace(/\$\{web_page\}/g, "页面");
    } else if (key === "text" && val && typeof val === "object") {
      desc = desc.replace(/\$\{text\}/g, val.content ?? String(val));
    } else if (typeof val === "string" || typeof val === "number") {
      desc = desc.replace(new RegExp(`\\$\\{${key}\\}`, "g"), String(val));
    }
  }
  return desc;
}

function buildFormData(unionId, params = {}) {
  const fail = defaultFailOptions();
  switch (unionId) {
    case "OpenUrl":
      return {
        launchOptions: {},
        failOptions: fail,
        newPageOptions: {
          defaultTimeout: String(params.pageTimeout ?? params.timeout ?? "120000"),
        },
        sendMsgFlag: true,
        url: params.url,
        browserType: params.browserType ?? "CHROME",
        navigateOptions: params.navigateOptions ?? {
          timeout: String(params.timeout ?? "120000"),
          waitUntil: params.waitUntil ?? "LOAD",
        },
        toolDesc: `打开网页 url:${params.url}`,
      };
    case "NavigateToUrl":
      return {
        rawUrl: params.url ?? params.rawUrl,
        navigateOptions: params.navigateOptions ?? {
          timeout: String(params.timeout ?? "30000"),
          waitUntil: params.waitUntil ?? "LOAD",
        },
        failOptions: fail,
        sendMsgFlag: true,
        toolDesc: `导航到 url:${params.url ?? params.rawUrl}`,
      };
    case "FillText": {
      const alias =
        params.selector?.alias ||
        params.selectorAlias ||
        "定位目标输入框，用于输入文本";
      const selectorId = buildSelectorId(alias);
      const text = params.text ?? "";
      const formData = {
        selectorId,
        locatorOptions: {},
        fillOptions: {},
        dynamicTextOptions: {},
        showEncryptedInfo: "false",
        masked: false,
        text: { content: text, textGenerateMode: "preset" },
        findElementOptions: findElementOptions(params),
        sendMsgFlag: true,
        failOptions: fail,
        toolDesc: `在页面${alias}元素中输入${text}`,
      };
      return formData;
    }
    case "ClickElementMixed": {
      const alias =
        params.selector?.alias ||
        params.selectorAlias ||
        "定位目标按钮，用于点击";
      const selectorId = buildSelectorId(alias);
      return {
        selectorId,
        failOptions: fail,
        clickOptions: {
          button: "LEFT",
          clickCount: "1",
          modifiers: [],
        },
        findElementOptions: findElementOptions(params),
        sendMsgFlag: true,
        toolDesc: `点击页面${alias}元素`,
      };
    }
    case "ReloadPage":
      return {
        reloadOptions: { waitUntil: "LOAD", timeout: "30000" },
        toolDesc: "刷新网页",
        failOptions: fail,
        sendMsgFlag: true,
      };
    case "GetText": {
      const alias = params.selector?.alias || params.selectorAlias || "定位目标元素，用于获取文本";
      return {
        selectorId: buildSelectorId(alias),
        findElementOptions: findElementOptions(params),
        failOptions: fail,
        sendMsgFlag: true,
        outKey: params.outKey ?? "",
        toolDesc: `获取${alias}的文本`,
      };
    }
    case "VerifyElementPresent":
    case "VerifyElementVisible":
    case "VerifyElementNotPresent":
    case "VerifyElementNotVisible":
    case "WaitForElementPresent":
    case "WaitForElementNotPresent":
    case "ScrollToElement":
    case "MouseOver": {
      const alias = params.selector?.alias || params.selectorAlias || "定位目标元素";
      return {
        selectorId: buildSelectorId(alias),
        findElementOptions: findElementOptions(params),
        failOptions: fail,
        sendMsgFlag: true,
        toolDesc: alias,
      };
    }
    case "SendKeys": {
      const alias = params.selector?.alias || params.selectorAlias || "定位目标元素";
      return {
        selectorId: buildSelectorId(alias),
        keys: params.keys ?? params.sendKeys ?? "Return",
        pressOptions: params.pressOptions ?? {},
        findElementOptions: findElementOptions(params),
        failOptions: fail,
        sendMsgFlag: true,
        toolDesc: `在${alias}模拟键盘输入 ${params.keys ?? params.sendKeys ?? "Return"}`,
      };
    }
    case "VerifyTextPresent":
    case "VerifyTextNotPresent":
      return {
        text: params.text ?? "",
        failOptions: fail,
        sendMsgFlag: true,
        toolDesc: `验证文本${params.text ?? ""}`,
      };
    case "WaitPageState":
      return {
        loadState: params.loadState ?? "LOAD",
        waitForLoadStateOptions: params.waitForLoadStateOptions ?? {
          timeout: String(params.timeout ?? "30000"),
        },
        failOptions: fail,
        sendMsgFlag: true,
        toolDesc: `等待页面${params.loadState ?? "LOAD"}`,
      };
    case "GetUrl":
    case "GetWindowTitle":
    case "GetWindowIndex":
      return {
        outKey: params.outKey ?? "",
        failOptions: fail,
        sendMsgFlag: true,
        toolDesc: unionId,
      };
    case "TakeScreenshot":
      return {
        screenshotOption: params.screenshotOption ?? { fullPage: true },
        outKey: params.outKey ?? "screenshotPath",
        failOptions: fail,
        sendMsgFlag: true,
        toolDesc: "截图",
      };
    case "ScrollToPosition": {
      const alias =
        params.selector?.alias ||
        params.selectorAlias ||
        "定位左侧导航菜单栏容器，用于按偏移量滚动";
      return {
        selectorId: buildSelectorId(alias),
        x: String(params.x ?? "0"),
        y: String(params.y ?? params.scrollY ?? "600"),
        findElementOptions: findElementOptions(params),
        failOptions: fail,
        sendMsgFlag: true,
        toolDesc: `在${alias}按偏移量滚动 x:${params.x ?? 0} y:${params.y ?? params.scrollY ?? 600}`,
      };
    }
    case "BackPage":
    case "ForwardPage":
      return { failOptions: fail, sendMsgFlag: true, toolDesc: unionId };
    case "Delay":
      return {
        second: String(params.second ?? params.delay ?? params.ms ?? "1"),
        timeUnit: params.timeUnit ?? "SECOND",
        failOptions: fail,
        sendMsgFlag: true,
        toolDesc: `延迟 ${params.second ?? params.delay ?? "1"} 秒`,
      };
    default:
      throw new Error(`暂不支持构建 formData: unionId=${unionId}`);
  }
}

export function buildRpaNode(meta, formData) {
  const toolDesc = formData.toolDesc || renderToolDesc(meta.showDesc, formData);
  return {
    type: "rpaNode",
    attrs: {
      canvasPosition: null,
      tag: meta.unionId,
      icon: "",
      nodeId: generateId(),
      disabled: false,
      nodeConfigState: "done",
      breakpoints: false,
      actionType: "",
      originalData: null,
      data: {
        skillName: meta.skillName,
        aiShowDesc: "",
        toolDesc,
        commandType: meta.commandType ?? 1,
        unionId: meta.unionId,
        icon: meta.icon,
        showDesc: meta.showDesc,
        formData: { ...formData, toolDesc },
        id: meta.id,
        title: meta.skillName,
      },
    },
  };
}

/**
 * @param {Array<{ unionId: string, params?: object, commandId?: number }>} instructionPlan
 */
export async function buildNodesFromPlan(instructionPlan) {
  const listMap = await fetchCommandList();
  const nodes = [];

  for (const step of instructionPlan) {
    const unionId = step.unionId;
    if (!ALLOWED_UNION_IDS.has(unionId)) {
      throw new Error(`一期不支持指令 unionId=${unionId}`);
    }
    const { meta } = await resolveCommandMeta(unionId, listMap);
    if (step.commandId && step.commandId !== meta.id) {
      console.warn(`warn: plan commandId ${step.commandId} != list ${meta.id} for ${unionId}`);
    }
    const formData = buildFormData(unionId, step.params || {});
    nodes.push(buildRpaNode(meta, formData));
  }
  return nodes;
}
