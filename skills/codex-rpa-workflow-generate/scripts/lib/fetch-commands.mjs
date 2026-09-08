#!/usr/bin/env node
/** 拉取指令列表与详情，带本地缓存 */

import { readFileSync, writeFileSync, mkdirSync, existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { getAuthHeaders, API_BASE } from "./auth.mjs";

const __dirname = dirname(fileURLToPath(import.meta.url));
const CACHE_DIR = join(__dirname, "../../data");
const LIST_CACHE = join(CACHE_DIR, "commands-list.json");
const CACHE_TTL_MS = 30 * 60 * 1000;

async function apiGet(path) {
  const headers = getAuthHeaders();
  const res = await fetch(`${API_BASE}${path}`, { headers });
  if (!res.ok) {
    throw new Error(`API ${path} HTTP ${res.status}`);
  }
  const body = await res.json();
  if (body.code !== 0) {
    throw new Error(`API ${path} code=${body.code} msg=${body.msg}`);
  }
  return body.data;
}

function readCache(file, ttlMs) {
  if (!existsSync(file)) return null;
  try {
    const cached = JSON.parse(readFileSync(file, "utf8"));
    if (Date.now() - cached.ts < ttlMs) {
      return cached.data;
    }
  } catch {
    /* ignore */
  }
  return null;
}

function writeCache(file, data) {
  mkdirSync(dirname(file), { recursive: true });
  writeFileSync(file, JSON.stringify({ ts: Date.now(), data }, null, 2));
}

/** 扁平化 listAll 树 → unionId → meta */
function flattenCommandTree(nodes, out = new Map()) {
  if (!Array.isArray(nodes)) return out;
  for (const node of nodes) {
    if (!node || typeof node !== "object") continue;
    const unionId = node.unionId || node.name;
    if (unionId && node.id && node.commandType === 1 && node.rpaNodeType !== "block") {
      out.set(unionId, {
        id: node.id,
        unionId,
        skillName: node.skillName || node.displayName || node.name,
        showDesc: node.showDesc || "",
        icon: node.icon || "",
        commandType: node.commandType ?? 1,
      });
    }
    const children = node.children || node.childList || [];
    flattenCommandTree(children, out);
  }
  return out;
}

export async function fetchCommandList(force = false) {
  if (!force) {
    const cached = readCache(LIST_CACHE, CACHE_TTL_MS);
    if (cached) return new Map(Object.entries(cached));
  }
  const tree = await apiGet("/api/v1/command/listAll?source=1");
  const map = flattenCommandTree(tree);
  writeCache(LIST_CACHE, Object.fromEntries(map));
  return map;
}

const detailCache = new Map();

export async function fetchCommandDetail(commandId) {
  if (detailCache.has(commandId)) {
    return detailCache.get(commandId);
  }
  const data = await apiGet(
    `/api/commandManage/getCommandDetail?commandId=${commandId}&userInfoFlag=0`,
  );
  detailCache.set(commandId, data);
  return data;
}

export async function resolveCommandMeta(unionId, listMap) {
  const meta = listMap.get(unionId);
  if (!meta) {
    throw new Error(`未找到 Web 原子指令 unionId=${unionId}`);
  }
  const detail = await fetchCommandDetail(meta.id);
  return { meta, detail };
}
