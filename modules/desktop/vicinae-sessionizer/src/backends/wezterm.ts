import { basename, join } from "path";
import { readdirSync, statSync } from "fs";
import { CommandError, runAsync, runDetached } from "../exec";
import { log } from "../log";
import type { TerminalBackend, OpenProject } from "./index";

interface WzClient {
  focused_workspace: string;
  focused_pane_id: number;
  focused_tab_id: number;
  activity_time_stamp: string;
}

interface WzPane {
  pane_id: number;
  tab_id: number;
  window_id: number;
  workspace: string;
  title: string;
  cwd: string;
}

interface Anchor {
  paneId: number;
  workspace: string;
}

// vicinae inherits a display env (WAYLAND_DISPLAY etc.) that may or may not
// match what wezterm GUI is using. Rather than trust the auto-discovered
// symlinks — which can dangle when a wezterm crashes — we pick the live
// gui-sock-<pid> directly from /run/user/$UID/wezterm and pass it via
// WEZTERM_UNIX_SOCKET. This pins every cli call to the actual running GUI.
function findGuiSocket(): string | null {
  const uid = typeof process.getuid === "function" ? process.getuid() : null;
  if (uid === null) return null;
  const dir = `/run/user/${uid}/wezterm`;
  let entries: string[];
  try {
    entries = readdirSync(dir);
  } catch {
    return null;
  }
  for (const name of entries) {
    if (!name.startsWith("gui-sock-")) continue;
    const full = join(dir, name);
    try {
      const st = statSync(full);
      if (st.isSocket()) {
        const pid = Number(name.slice("gui-sock-".length));
        if (Number.isFinite(pid) && isProcessAlive(pid)) return full;
      }
    } catch {
      // socket vanished between readdir and stat; ignore
    }
  }
  return null;
}

function isProcessAlive(pid: number): boolean {
  try {
    process.kill(pid, 0);
    return true;
  } catch {
    return false;
  }
}

function cliEnv(): NodeJS.ProcessEnv {
  const base = { ...process.env };
  const sock = findGuiSocket();
  if (sock) {
    base.WEZTERM_UNIX_SOCKET = sock;
    log.debug("wezterm", "pinned GUI socket", { sock });
  } else {
    log.debug("wezterm", "no live GUI socket; letting wezterm auto-discover");
  }
  return base;
}

function isMuxDown(err: unknown): boolean {
  if (!(err instanceof CommandError)) return false;
  return /failed to connect|No such file or directory/i.test(err.stderr);
}

async function wzList(): Promise<WzPane[]> {
  return JSON.parse(
    await runAsync("wezterm", ["cli", "list", "--format", "json"], {
      env: cliEnv(),
    }),
  );
}

async function wzClients(): Promise<WzClient[]> {
  try {
    return JSON.parse(
      await runAsync("wezterm", ["cli", "list-clients", "--format", "json"], {
        env: cliEnv(),
      }),
    );
  } catch (err) {
    log.warn("wezterm", "list-clients failed", { err: String(err) });
    return [];
  }
}

async function currentAnchor(): Promise<Anchor | null> {
  const clients = await wzClients();
  if (clients.length === 0) return null;
  const latest = clients.reduce((a, b) =>
    a.activity_time_stamp > b.activity_time_stamp ? a : b,
  );
  if (!Number.isFinite(latest.focused_pane_id)) return null;
  return {
    paneId: latest.focused_pane_id,
    workspace: latest.focused_workspace || "",
  };
}

function uniqueWorkspaceName(base: string, existing: Set<string>): string {
  if (!existing.has(base)) return base;
  for (let i = 2; ; i++) {
    const candidate = `${base}-${i}`;
    if (!existing.has(candidate)) return candidate;
  }
}

function cmdTail(cmd: string[]): string[] {
  return cmd.length > 0 ? ["--", ...cmd] : [];
}

// Boot a GUI + mux and land in the named workspace/cwd. Used only when no
// wezterm GUI is running at all.
function startGui(workspace: string, cwd: string, cmd: string[]): void {
  log.info("wezterm", "starting GUI (no live socket found)", {
    workspace,
    cwd,
  });
  runDetached("wezterm", [
    "start",
    "--workspace",
    workspace,
    "--cwd",
    cwd,
    ...cmdTail(cmd),
  ]);
}

function wzRun(args: string[]): Promise<string> {
  return runAsync("wezterm", args, { env: cliEnv() });
}

export class WeztermBackend implements TerminalBackend {
  async openSession(sessionId: string, cwd: string, cmd: string[] = []) {
    if (!findGuiSocket()) {
      startGui(sessionId, cwd, cmd);
      return;
    }
    let panes: WzPane[];
    try {
      panes = await wzList();
    } catch (err) {
      if (isMuxDown(err)) {
        startGui(sessionId, cwd, cmd);
        return;
      }
      throw err;
    }
    const match = panes.find((p) => p.workspace === sessionId);
    if (match) {
      log.info("wezterm", "focusing existing workspace", {
        sessionId,
        paneId: match.pane_id,
      });
      await wzRun(["cli", "activate-pane", "--pane-id", String(match.pane_id)]);
      return;
    }
    const anchor = await currentAnchor();
    const args = ["cli", "spawn", "--workspace", sessionId, "--cwd", cwd];
    if (anchor) args.push("--pane-id", String(anchor.paneId));
    log.info("wezterm", "spawning workspace tab", { sessionId, anchor });
    await wzRun([...args, ...cmdTail(cmd)]);
  }

  async addTabToCurrent(cwd: string, cmd: string[] = []) {
    if (!findGuiSocket()) {
      startGui(basename(cwd) || "scratch", cwd, cmd);
      return;
    }
    const anchor = await currentAnchor();
    if (!anchor) {
      log.info("wezterm", "no focused pane; falling back to new workspace");
      return this.openInNewWorkspace(basename(cwd) || "scratch", cwd, cmd);
    }
    log.info("wezterm", "adding tab anchored to current pane", { anchor, cwd });
    await wzRun([
      "cli",
      "spawn",
      "--pane-id",
      String(anchor.paneId),
      "--cwd",
      cwd,
      ...cmdTail(cmd),
    ]);
  }

  async addPaneToCurrent(cwd: string, cmd: string[] = []) {
    if (!findGuiSocket()) {
      startGui(basename(cwd) || "scratch", cwd, cmd);
      return;
    }
    const anchor = await currentAnchor();
    if (!anchor) {
      log.info(
        "wezterm",
        "no focused pane; pane split needs target — using new workspace",
      );
      return this.openInNewWorkspace(basename(cwd) || "scratch", cwd, cmd);
    }
    log.info("wezterm", "splitting focused pane", { anchor, cwd });
    await wzRun([
      "cli",
      "split-pane",
      "--pane-id",
      String(anchor.paneId),
      "--right",
      "--cwd",
      cwd,
      ...cmdTail(cmd),
    ]);
  }

  async openInNewWorkspace(sessionId: string, cwd: string, cmd: string[] = []) {
    if (!findGuiSocket()) {
      startGui(sessionId, cwd, cmd);
      return;
    }
    const existing = new Set((await wzList()).map((p) => p.workspace));
    const name = uniqueWorkspaceName(sessionId, existing);
    // Anchor to the current pane so the new workspace appears in the existing
    // window rather than spawning a second one.
    const anchor = await currentAnchor();
    const args = ["cli", "spawn", "--workspace", name, "--cwd", cwd];
    if (anchor) args.push("--pane-id", String(anchor.paneId));
    log.info("wezterm", "spawning new workspace", { name, cwd, anchor });
    await wzRun([...args, ...cmdTail(cmd)]);
  }

  async listOpenProjects(roots: string[]): Promise<OpenProject[]> {
    if (!findGuiSocket()) {
      log.info("wezterm", "no GUI running; returning empty project list");
      return [];
    }
    let panes: WzPane[];
    try {
      panes = await wzList();
    } catch (err) {
      if (isMuxDown(err)) {
        log.info("wezterm", "mux unreachable; returning empty project list");
        return [];
      }
      throw err;
    }
    const resolvedRoots = roots.map((r) => r.replace(/\/$/, ""));
    const cwdFor = (p: WzPane): string => {
      const m = p.cwd.match(/^file:\/\/[^/]*(\/.*)$/);
      return m ? m[1] : p.cwd;
    };
    const underRoot = (cwd: string) =>
      resolvedRoots.some((r) => cwd === r || cwd.startsWith(r + "/"));

    const seen = new Set<string>();
    const out: OpenProject[] = [];
    for (const pane of panes) {
      const cwd = cwdFor(pane);
      if (!underRoot(cwd)) continue;
      const key = `${pane.tab_id}::${cwd}`;
      if (seen.has(key)) continue;
      seen.add(key);
      out.push({
        cwd,
        workspace: pane.workspace,
        tabTitle: pane.title,
        clientId: String(pane.pane_id),
      });
    }
    return out;
  }
}
