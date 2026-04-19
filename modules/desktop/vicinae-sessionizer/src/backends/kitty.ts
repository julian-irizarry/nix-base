import { basename } from "path";
import { runAsync, runDetached, runSync } from "../exec";
import { log } from "../log";
import type { TerminalBackend, OpenProject } from "./index";

interface KittyWindow {
  id: number;
  cwd: string;
  title: string;
}

interface KittyTab {
  id: number;
  title: string;
  is_active: boolean;
  windows: KittyWindow[];
}

interface KittyOsWindow {
  id: number;
  is_focused: boolean;
  tabs: KittyTab[];
}

const KITTY_SOCKET = "unix:/tmp/kitty";

function kittenArgs(rest: string[]): string[] {
  return ["@", "--to", KITTY_SOCKET, ...rest];
}

function focusTabByTitle(title: string): boolean {
  try {
    runSync("kitten", kittenArgs(["focus-tab", "--match", `title:${title}`]));
    return true;
  } catch {
    return false;
  }
}

function launchTab(title: string, cwd: string, cmd: string[]): void {
  runDetached(
    "kitten",
    kittenArgs([
      "launch",
      "--type=tab",
      `--title=${title}`,
      `--cwd=${cwd}`,
      ...cmd,
    ]),
  );
}

export class KittyBackend implements TerminalBackend {
  async openSession(sessionId: string, cwd: string, cmd: string[] = []) {
    if (focusTabByTitle(sessionId)) {
      log.info("kitty", "focused existing tab", { sessionId });
      return;
    }
    log.info("kitty", "launching tab", { sessionId, cwd });
    launchTab(sessionId, cwd, cmd);
  }

  async addTabToCurrent(cwd: string, cmd: string[] = []) {
    log.info("kitty", "adding tab", { cwd });
    launchTab(basename(cwd), cwd, cmd);
  }

  async addPaneToCurrent(cwd: string, cmd: string[] = []) {
    log.info("kitty", "splitting current window", { cwd });
    runDetached(
      "kitten",
      kittenArgs([
        "launch",
        "--type=window",
        "--location=vsplit",
        `--cwd=${cwd}`,
        ...cmd,
      ]),
    );
  }

  async openInNewWorkspace(sessionId: string, cwd: string, cmd: string[] = []) {
    log.info("kitty", "launching tab (no native workspace concept)", {
      sessionId,
      cwd,
    });
    launchTab(sessionId, cwd, cmd);
  }

  async listOpenProjects(roots: string[]): Promise<OpenProject[]> {
    const osWindows: KittyOsWindow[] = JSON.parse(
      await runAsync("kitten", kittenArgs(["ls"])),
    );
    const resolvedRoots = roots.map((r) => r.replace(/\/$/, ""));
    const underRoot = (cwd: string) =>
      resolvedRoots.some((r) => cwd === r || cwd.startsWith(r + "/"));

    const seen = new Set<string>();
    const out: OpenProject[] = [];
    for (const osw of osWindows) {
      for (const tab of osw.tabs) {
        for (const w of tab.windows) {
          if (!underRoot(w.cwd)) continue;
          const key = `${tab.id}::${w.cwd}`;
          if (seen.has(key)) continue;
          seen.add(key);
          out.push({
            cwd: w.cwd,
            workspace: null,
            tabTitle: tab.title,
            clientId: String(tab.id),
          });
        }
      }
    }
    return out;
  }
}
