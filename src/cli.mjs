// skilldev CLI entry: parse argv, dispatch to a command module.

import { CliError, err, c } from "./lib/log.mjs";

import cmdNew from "./commands/new.mjs";
import cmdList from "./commands/list.mjs";
import cmdValidate from "./commands/validate.mjs";
import cmdBuild from "./commands/build.mjs";
import cmdInstall from "./commands/install.mjs";
import cmdPack from "./commands/pack.mjs";
import cmdVersion from "./commands/version.mjs";
import cmdManifest from "./commands/manifest.mjs";
import cmdDoctor from "./commands/doctor.mjs";

const COMMANDS = {
  new: cmdNew,
  list: cmdList,
  validate: cmdValidate,
  build: cmdBuild,
  install: cmdInstall,
  pack: cmdPack,
  version: cmdVersion,
  manifest: cmdManifest,
  doctor: cmdDoctor,
};

// Flags that never take a value.
const BOOLEAN_FLAGS = new Set([
  "dry-run",
  "link",
  "all",
  "help",
  "install-deps",
  "json",
  "force",
]);

export function parseArgs(argv) {
  const positionals = [];
  const flags = {};
  for (let i = 0; i < argv.length; i++) {
    const tok = argv[i];
    if (tok.startsWith("--")) {
      const body = tok.slice(2);
      const eq = body.indexOf("=");
      if (eq !== -1) {
        flags[body.slice(0, eq)] = body.slice(eq + 1);
      } else if (BOOLEAN_FLAGS.has(body)) {
        flags[body] = true;
      } else {
        const next = argv[i + 1];
        if (next !== undefined && !next.startsWith("--")) {
          flags[body] = next;
          i++;
        } else {
          flags[body] = true;
        }
      }
    } else {
      positionals.push(tok);
    }
  }
  return { positionals, flags };
}

function usage() {
  console.log(`${c.bold("skilldev")} — develop & publish agent skills across ecosystems

Usage: skilldev <command> [args] [--flags]

Commands:
  new <name>                       Scaffold a new skill
  list                             List skills (name / version / targets)
  validate [skill]                 Validate one or all skills
  build [skill] [--target <id|all>]  Build to dist/<target>/<name>/
  install <skill> [--target <id|all>] [--link] [--dry-run] [--install-deps]
                                   Install into the ecosystem's skills dir
  pack <skill> [--dry-run]         Package an automan zip: dist/<name>_<version>.zip
  version <skill> <major|minor|patch|x.y.z>   Bump a skill's version
  manifest [--dry-run]             Generate repo-level plugin manifests
  doctor                           Environment self-check

Ecosystems: claude, codex, cursor, automan  (paths overridable via env — see README)`);
}

export async function run(argv) {
  const { positionals, flags } = parseArgs(argv);
  const command = positionals.shift();

  if (!command || command === "help" || flags.help) {
    usage();
    return command ? 0 : 1;
  }

  const handler = COMMANDS[command];
  if (!handler) {
    err(`unknown command: ${command}`);
    usage();
    return 1;
  }

  try {
    await handler({ positionals, flags });
    return 0;
  } catch (e) {
    if (e instanceof CliError) {
      err(e.message);
    } else {
      err(e && e.stack ? e.stack : String(e));
    }
    return 1;
  }
}
