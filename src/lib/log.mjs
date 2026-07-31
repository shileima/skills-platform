// Tiny logging helpers with light ANSI color (auto-disabled when not a TTY).

const useColor = process.stdout.isTTY && process.env.NO_COLOR === undefined;
const paint = (code, s) => (useColor ? `\x1b[${code}m${s}\x1b[0m` : s);

export const c = {
  bold: (s) => paint("1", s),
  dim: (s) => paint("2", s),
  red: (s) => paint("31", s),
  green: (s) => paint("32", s),
  yellow: (s) => paint("33", s),
  blue: (s) => paint("34", s),
  cyan: (s) => paint("36", s),
};

export const info = (...args) => console.log(...args);
export const ok = (msg) => console.log(`${c.green("✓")} ${msg}`);
export const warn = (msg) => console.warn(`${c.yellow("!")} ${msg}`);
export const err = (msg) => console.error(`${c.red("✗")} ${msg}`);
export const step = (msg) => console.log(`${c.cyan("→")} ${msg}`);

// A thrown CliError is reported as a clean message (no stack) by the CLI entry.
export class CliError extends Error {}
export const fail = (msg) => {
  throw new CliError(msg);
};
