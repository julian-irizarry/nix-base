import { basename } from "path";
import { runDetached } from "../exec";
import { log } from "../log";
import type { TerminalBackend, OpenSession } from "./index";

const KITTY_SOCKET = "unix:/tmp/kitty";

function kittenArgs(rest: string[]): string[] {
  return ["@", "--to", KITTY_SOCKET, ...rest];
}

export class KittyBackend implements TerminalBackend {
  private readonly bin: string;

  constructor(bin?: string) {
    this.bin = bin ?? "kitten";
  }

  private launchTab(title: string, cwd: string, cmd: string[]): void {
    runDetached(
      this.bin,
      kittenArgs([
        "launch",
        "--type=tab",
        `--title=${title}`,
        `--cwd=${cwd}`,
        ...cmd,
      ]),
    );
  }

  async addTabToFocused(cwd: string, cmd: string[] = []) {
    log.info("kitty", "adding tab", { cwd });
    this.launchTab(basename(cwd), cwd, cmd);
  }

  async addPaneToFocused(cwd: string, cmd: string[] = []) {
    log.info("kitty", "splitting current window", { cwd });
    runDetached(
      this.bin,
      kittenArgs([
        "launch",
        "--type=window",
        "--location=vsplit",
        `--cwd=${cwd}`,
        ...cmd,
      ]),
    );
  }

  async createWorkspace(sessionId: string, cwd: string, cmd: string[] = []) {
    log.info("kitty", "launching tab (no native workspace concept)", {
      sessionId,
      cwd,
    });
    this.launchTab(sessionId, cwd, cmd);
  }

  async focusSession(_session: OpenSession): Promise<void> {
    // Kitty has no workspace concept, and find-open-session is a
    // wezterm-only feature. Kitty users rely on the wezterm-only command
    // not being exposed, or see an empty list from listOpenSessions.
    throw new Error("find-open-session is not supported on the kitty backend");
  }

  async listOpenSessions(): Promise<OpenSession[]> {
    return [];
  }
}
