import { basename, join } from "path";
import { readdirSync, statSync } from "fs";
import { homedir } from "os";
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

// The host may run wezterm with a display env (WAYLAND_DISPLAY, or the Darwin
// Aqua session) that doesn't match what vicinae/raycast inherited. Rather
// than trust auto-discovered symlinks — which can dangle when a wezterm
// crashes — we pick the live gui-sock-<pid> from the OS-specific runtime
// dir and pass it via WEZTERM_UNIX_SOCKET. This pins every cli call to the
// actual running GUI.
//   Linux: /run/user/$UID/wezterm/gui-sock-<pid>
//   Darwin: ~/.local/share/wezterm/gui-sock-<pid> (wezterm falls back here
//           because XDG_RUNTIME_DIR is typically unset on macOS)
function guiSocketDir(): string | null {
  if (process.platform === "linux") {
    const uid = typeof process.getuid === "function" ? process.getuid() : null;
    if (uid === null) return null;
    return `/run/user/${uid}/wezterm`;
  }
  if (process.platform === "darwin") {
    return join(homedir(), ".local", "share", "wezterm");
  }
  return null;
}

function findGuiSocket(): string | null {
  const dir = guiSocketDir();
  if (dir === null) return null;
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

function parsePaneId(stdout: string): number | null {
  const line = stdout.trim().split(/\r?\n/).pop() ?? "";
  if (line === "") return null;
  const n = Number(line);
  return Number.isFinite(n) ? n : null;
}

export class WeztermBackend implements TerminalBackend {
  private readonly bin: string;

  constructor(bin?: string) {
    this.bin = bin ?? "wezterm";
  }

  private wzRun(args: string[]): Promise<string> {
    return runAsync(this.bin, args, { env: cliEnv() });
  }

  private async wzList(): Promise<WzPane[]> {
    return JSON.parse(
      await runAsync(this.bin, ["cli", "list", "--format", "json"], {
        env: cliEnv(),
      }),
    );
  }

  private async wzClients(): Promise<WzClient[]> {
    try {
      return JSON.parse(
        await runAsync(this.bin, ["cli", "list-clients", "--format", "json"], {
          env: cliEnv(),
        }),
      );
    } catch (err) {
      log.warn("wezterm", "list-clients failed", { err: String(err) });
      return [];
    }
  }

  private async currentAnchor(): Promise<Anchor | null> {
    const clients = await this.wzClients();
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

  // Boot a GUI + mux and land in the named workspace/cwd. Used only when no
  // wezterm GUI is running at all.
  private startGui(workspace: string, cwd: string, cmd: string[]): void {
    log.info("wezterm", "starting GUI (no live socket found)", {
      workspace,
      cwd,
    });
    runDetached(this.bin, [
      "start",
      "--workspace",
      workspace,
      "--cwd",
      cwd,
      ...cmdTail(cmd),
    ]);
  }

  async addTabToFocused(cwd: string, cmd: string[] = []) {
    if (!findGuiSocket()) {
      // First-run launcher path: no wezterm running at all.
      log.info("wezterm", "no GUI running; launching as first workspace", {
        cwd,
      });
      this.startGui(basename(cwd) || "scratch", cwd, cmd);
      return;
    }
    const anchor = await this.currentAnchor();
    if (!anchor) {
      log.info(
        "wezterm",
        "mux alive but no focused pane; falling through to createWorkspace",
        { cwd },
      );
      return this.createWorkspace(basename(cwd) || "scratch", cwd, cmd);
    }
    log.info("wezterm", "adding tab to focused pane's window", { anchor, cwd });
    await this.wzRun([
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
      this.startGui(basename(cwd) || "scratch", cwd, cmd);
      return;
    }
    const anchor = await this.currentAnchor();
    if (!anchor) {
      log.info(
        "wezterm",
        "mux alive but no focused pane; falling through to createWorkspace",
        { cwd },
      );
      return this.createWorkspace(basename(cwd) || "scratch", cwd, cmd);
    }
    log.info("wezterm", "splitting focused pane", { anchor, cwd });
    await this.wzRun([
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
      this.startGui(sessionId, cwd, cmd);
      return;
    }
    const existing = new Set((await this.wzList()).map((p) => p.workspace));
    const name = uniqueWorkspaceName(sessionId, existing);
    log.info("wezterm", "spawning new workspace in new window", { name, cwd });
    // --new-window is required when --workspace is passed without --pane-id.
    const stdout = await this.wzRun([
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
    const workspaces = new Set((await this.wzList()).map((p) => p.workspace));
    if (!workspaces.has(session.workspace)) {
      log.warn("wezterm", "focusSession: workspace no longer exists", {
        session,
      });
      throw new Error(`workspace "${session.workspace}" no longer exists`);
    }
    // Any pane in the mux works as the user-var target; the lua listener
    // uses the var's value (workspace name), not the source pane.
    const anyPane = (await this.wzList())[0];
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
      panes = await this.wzList();
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
      this.bin,
      ["cli", "send-text", "--pane-id", String(paneId), "--no-paste"],
      osc,
      { env: cliEnv() },
    );
  }
}
