import { execFileSync, spawn } from "child_process";
import { basename } from "path";
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

function kittenJson<T>(args: string[]): T {
  const out = execFileSync("kitten", ["@", "--to", KITTY_SOCKET, ...args], {
    encoding: "utf8",
  });
  return JSON.parse(out) as T;
}

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

  async addTabToCurrent(cwd: string, cmd: string[] = []) {
    launchTab(basename(cwd), cwd, cmd);
  }

  async addPaneToCurrent(cwd: string, cmd: string[] = []) {
    spawn(
      "kitten",
      [
        "@",
        "--to",
        KITTY_SOCKET,
        "launch",
        "--type=window",
        "--location=vsplit",
        `--cwd=${cwd}`,
        ...cmd,
      ],
      { detached: true, stdio: "ignore" },
    ).unref();
  }

  async openInNewWorkspace(sessionId: string, cwd: string, cmd: string[] = []) {
    // Kitty has no workspaces — behave like addTabToCurrent with explicit title.
    launchTab(sessionId, cwd, cmd);
  }

  async listOpenProjects(roots: string[]): Promise<OpenProject[]> {
    const osWindows = kittenJson<KittyOsWindow[]>(["ls"]);
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
