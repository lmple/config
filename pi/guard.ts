// pi extension loaded by pi/local.sh only: it gives pi on the local model the
// tool rules gptel has in Emacs (doom/lisp/llm-tools.el). pi itself never
// asks before a tool runs, and a small local model is easy to steer through
// a prompt injected into any file it reads. So, as for gptel:
// - nothing reaches the files that hold keys and credentials;
// - every edit and write is shown to the user first, and refused without
//   a terminal to ask in;
// - no other tool runs, whatever --tools lets through (bash above all).
// Only type imports from pi, so plain node can load this file to test it.

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { realpathSync } from "node:fs";
import { homedir } from "node:os";
import { basename, dirname, isAbsolute, join, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";

// Keep in sync with my/gptel-tool-denied-paths in doom/lisp/llm-tools.el.
// Directories end with "/". /proc is extra: a process's environment is one
// read away there, and pi, unlike Emacs, runs with the model's requests.
const DENIED_PATHS = [
  "~/.ssh/", "~/.gnupg/", "~/.password-store/", "~/.aws/",
  "~/.config/llama-server/", "~/.extra_config", "~/.authinfo", "~/.netrc",
  "~/.claude/", "~/.local/share/keyrings/", "/proc/",
];
// Same as my/gptel-tool-denied-regexp: encrypted files
const DENIED_NAME = /\.(gpg|age)$/;

const READING = new Set(["read", "ls", "find", "grep"]);
const WRITING = new Set(["edit", "write"]);

export type Decision =
  | { block: string } // refuse, telling the model why
  | { confirm: string } // ask the user first
  | undefined; // let it run

// Resolve as pi's tools do (resolveToCwd in pi's core/tools/path-utils.js),
// or the check and the tool could disagree on which file is meant.
function toolPath(input: string, cwd: string): string {
  let path = input.replace(/[\u00A0\u2000-\u200A\u202F\u205F\u3000]/g, " ");
  if (path.startsWith("@")) path = path.slice(1);
  if (path === "~") path = homedir();
  else if (path.startsWith("~/")) path = join(homedir(), path.slice(2));
  if (path.startsWith("file://")) path = fileURLToPath(path);
  return isAbsolute(path) ? resolve(path) : resolve(cwd, path);
}

// Follow symlinks, so a link into ~/.ssh is refused too. A file that doesn't
// exist yet (write) is checked through the nearest directory that does.
function truename(path: string): string {
  try {
    return realpathSync(path);
  } catch {
    const parent = dirname(path);
    return parent === path ? path : join(truename(parent), basename(path));
  }
}

function within(path: string, dir: string): boolean {
  return path === dir || path.startsWith(dir.endsWith(sep) ? dir : dir + sep);
}

function denied(): { path: string; isDir: boolean }[] {
  return DENIED_PATHS.map((p) => ({ path: truename(toolPath(p, "/")), isDir: p.endsWith("/") }));
}

export function decide(tool: string, input: Record<string, unknown>, cwd: string): Decision {
  if (!READING.has(tool) && !WRITING.has(tool)) {
    return { block: `The ${tool} tool isn't available with the local model.` };
  }
  // grep, find and ls default to the working directory
  const given = typeof input.path === "string" && input.path !== "" ? input.path : ".";
  const path = truename(toolPath(given, cwd));

  for (const d of denied()) {
    if (d.isDir ? within(path, d.path) : path === d.path) {
      return { block: `${path} holds credentials and is off limits.` };
    }
  }
  if (DENIED_NAME.test(path)) {
    return { block: `${path} is encrypted and off limits.` };
  }
  // pi's grep runs ripgrep with --hidden, so searching a directory that holds
  // a denied one (~ holds ~/.ssh) would read inside it. find and ls only
  // return names, so they don't need this.
  if (tool === "grep") {
    const inside = denied().find((d) => within(d.path, path));
    if (inside) {
      return {
        block: `Searching ${path} would read ${inside.path}, which holds credentials; search a narrower directory, such as a project's.`,
      };
    }
  }

  if (tool === "write") {
    const lines = typeof input.content === "string" ? input.content.split("\n").length : 0;
    return { confirm: `Write ${lines} lines to ${path}?` };
  }
  if (tool === "edit") {
    const edits = Array.isArray(input.edits) ? input.edits.length : 0;
    return { confirm: `Make ${edits} edit${edits === 1 ? "" : "s"} to ${path}?` };
  }
  return undefined;
}

export default function (pi: ExtensionAPI) {
  pi.on("tool_call", async (event, ctx) => {
    const decision = decide(event.toolName, event.input as Record<string, unknown>, ctx.cwd);
    if (decision === undefined) return;
    if ("block" in decision) return { block: true, reason: decision.block };
    if (!ctx.hasUI) {
      return { block: true, reason: "Changing files needs the user's approval, and there is no terminal to ask in." };
    }
    if (!(await ctx.ui.confirm("Local model", decision.confirm))) {
      return { block: true, reason: "The user declined this change." };
    }
  });
}
