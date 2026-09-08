/** 与编辑器 @libs/utils generateId 一致：21 位纯字母数字 */

const ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

export function generateId(size = 21) {
  let id = "";
  for (let i = 0; i < size; i++) {
    id += ALPHABET[Math.floor(Math.random() * ALPHABET.length)];
  }
  return id;
}

/** 不入库元素 JSON 用的 workflowElementId（本地唯一即可） */
export function generateWorkflowElementId() {
  return Math.floor(Date.now() / 1000) * 1000 + Math.floor(Math.random() * 999);
}
