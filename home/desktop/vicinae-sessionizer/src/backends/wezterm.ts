import { basename, join } from "path";
import { readdirSync, statSync } from "fs";
import {
  CommandError,
  runAsync,
  runAsyncWithStdin,
  runDetached,
} from "../exec";
import { log } from "../log";
import type { TerminalBackend, OpenSession } from "./index";

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

function parsePaneId(stdout: string): number | null {
  const line = stdout.trim().split(/\r?\n/).pop() ?? "";
  if (line === "") return null;
  const n = Number(line);
  return Number.isFinite(n) ? n : null;
}

export class WeztermBackend implements TerminalBackend {
  async addTabToFocused(cwd: string, cmd: string[] = []) {
    if (!findGuiSocket()) {
      // First-run launcher path: no wezterm running at all.
      log.info("wezterm", "no GUI running; launching as first workspace", {
        cwd,
      });
      startGui(basename(cwd) || "scratch", cwd, cmd);
      return;
    }
    const anchor = await currentAnchor();
    if (!anchor) {
      log.info(
        "wezterm",
        "mux alive but no focused pane; falling through to createWorkspace",
        { cwd },
      );
      return this.createWorkspace(basename(cwd) || "scratch", cwd, cmd);
    }
    log.info("wezterm", "adding tab to focused pane's window", { anchor, cwd });
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

  async addPaneToFocused(cwd: string, cmd: string[] = []) {
    if (!findGuiSocket()) {
      log.info(
        "wezterm",
        "no GUI running; launching as first workspace (pane fallback)",
        { cwd },
      );
      startGui(basename(cwd) || "scratch", cwd, cmd);
      return;
    }
    const anchor = await currentAnchor();
    if (!anchor) {
      log.info(
        "wezterm",
        "mux alive but no focused pane; falling through to createWorkspace",
        { cwd },
      );
      return this.createWorkspace(basename(cwd) || "scratch", cwd, cmd);
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

  async createWorkspace(sessionId: string, cwd: string, cmd: string[] = []) {
    if (!findGuiSocket()) {
      log.info("wezterm", "no GUI running; starting with workspace", {
        sessionId,
      });
      startGui(sessionId, cwd, cmd);
      return;
    }
    const existing = new Set((await wzList()).map((p) => p.workspace));
    const name = uniqueWorkspaceName(sessionId, existing);
    log.info("wezterm", "spawning new workspace in new window", { name, cwd });
    // --new-window is required when --workspace is passed without --pane-id.
    const stdout = await wzRun([
      "cli",
      "spawn",
      "--workspace",
      name,
      "--new-window",
      "--cwd",
      cwd,
      ...cmdTail(cmd),
    ]);
    const newPaneId = parsePaneId(stdout);
    if (newPaneId === null) {
      log.warn("wezterm", "could not parse spawn stdout for new pane id", {
        stdout,
      });
      return;
    }
    // Cross-app focus via user-var: wezterm's lua listener catches this and
    // calls SwitchToWorkspace internally, which raises the window reliably
    // where an external activate-pane would be blocked by GNOME's focus
    // stealing prevention.
    await this.signalFocus(name, newPaneId);
  }

  async focusSession(session: OpenSession): Promise<void> {
    if (!findGuiSocket()) {
      log.warn("wezterm", "focusSession: no GUI running", { session });
      throw new Error("wezterm is not running");
    }
    const workspaces = new Set((await wzList()).map((p) => p.workspace));
    if (!workspaces.has(session.workspace)) {
      log.warn("wezterm", "focusSession: workspace no longer exists", {
        session,
      });
      throw new Error(`workspace "${session.workspace}" no longer exists`);
    }
    // Any pane in the mux works as the user-var target; the lua listener
    // uses the var's value (workspace name), not the source pane.
    const anyPane = (await wzList())[0];
    if (!anyPane) {
      throw new Error("no panes available to signal focus");
    }
    await this.signalFocus(session.workspace, anyPane.pane_id);
  }

  async listOpenSessions(): Promise<OpenSession[]> {
    if (!findGuiSocket()) {
      log.info("wezterm", "no GUI running; returning empty session list");
      return [];
    }
    let panes: WzPane[];
    try {
      panes = await wzList();
    } catch (err) {
      if (isMuxDown(err)) {
        log.info("wezterm", "mux unreachable; returning empty session list");
        return [];
      }
      throw err;
    }
    const workspaces = new Set(panes.map((p) => p.workspace));
    return [...workspaces].map((workspace) => ({ workspace }));
  }

  // Wezterm has no direct CLI for setting user vars. The documented pattern
  // is to write OSC 1337 SetUserVar escape sequence to a pane via send-text;
  // wezterm's terminal parser intercepts it and fires user-var-changed.
  // --no-paste prevents bracketed paste mode from wrapping (and breaking) the
  // OSC. stdin carries the raw bytes.
  private async signalFocus(workspace: string, paneId: number): Promise<void> {
    const encoded = Buffer.from(workspace, "utf8").toString("base64");
    const osc = `\x1b]1337;SetUserVar=SESSIONIZER_FOCUS=${encoded}\x07`;
    log.info("wezterm", "signalling focus via OSC 1337", { workspace, paneId });
    await runAsyncWithStdin(
      "wezterm",
      ["cli", "send-text", "--pane-id", String(paneId), "--no-paste"],
      osc,
      { env: cliEnv() },
    );
  }
}
