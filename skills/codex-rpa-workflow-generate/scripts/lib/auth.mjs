#!/usr/bin/env node
/** 从 Automan 本地配置读取 xcAuth，用于 digitalgateway API 鉴权 */

import { readFileSync, existsSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

const CONFIG_PATH = join(homedir(), "Library/Preferences/automan/config.json");

export function loadAutomanConfig() {
  if (!existsSync(CONFIG_PATH)) {
    throw new Error(`Automan 配置文件不存在: ${CONFIG_PATH}`);
  }
  return JSON.parse(readFileSync(CONFIG_PATH, "utf8"));
}

/** @returns {Record<string, string>} */
export function getAuthHeaders() {
  const cfg = loadAutomanConfig();
  const xcAuth = cfg.xcAuth;
  if (!xcAuth) {
    throw new Error("config.json 中缺少 xcAuth");
  }
  const headers = {
    "xc-auth": xcAuth,
  };
  if (cfg.tenantId) {
    headers["tenant-id"] = String(cfg.tenantId);
  }
  return headers;
}

export const API_BASE = "https://digitalgateway.sankuai.com/platform";
