import { execFileSync, spawn } from "child_process";
import type { TerminalBackend, OpenProject } from "./index";

const KITTY_SOCKET = "unix:/tmp/kitty";

function kitten(args: string[]): void {
  execFileSync("kitten", ["@", "--to", KITTY_SOCKET, ...args], {
    stdio: "ignore",
  });
}

function focusTabByTitle(title: string): boolean {
  try {
    kitten(["focus-tab", "--match", `title:${title}`]);
    return true;
  } catch {
    return false;
  }
}

function launchTab(title: string, cwd: string, cmd: string[]): void {
  const args = [
    "@",
    "--to",
    KITTY_SOCKET,
    "launch",
    "--type=tab",
    `--title=${title}`,
    `--cwd=${cwd}`,
    ...cmd,
  ];
  spawn("kitten", args, { detached: true, stdio: "ignore" }).unref();
}

export class KittyBackend implements TerminalBackend {
  async openSession(sessionId: string, cwd: string, cmd: string[] = []) {
    if (focusTabByTitle(sessionId)) return;
    launchTab(sessionId, cwd, cmd);
  }

  async addTabToCurrent(_cwd: string, _cmd: string[] = []) {
    throw new Error("KittyBackend.addTabToCurrent not implemented (stage 4)");
  }

  async addPaneToCurrent(_cwd: string, _cmd: string[] = []) {
    throw new Error("KittyBackend.addPaneToCurrent not implemented (stage 4)");
  }

  async openInNewWorkspace(
    _sessionId: string,
    _cwd: string,
    _cmd: string[] = [],
  ) {
    throw new Error(
      "KittyBackend.openInNewWorkspace not implemented (stage 4)",
    );
  }

  async listOpenProjects(_roots: string[]): Promise<OpenProject[]> {
    throw new Error("KittyBackend.listOpenProjects not implemented (stage 4)");
  }
}
