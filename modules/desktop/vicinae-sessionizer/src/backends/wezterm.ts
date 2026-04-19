import { execFileSync, spawn } from "child_process";
import { basename } from "path";
import type { TerminalBackend, OpenProject } from "./index";

interface WzClient {
  focused_workspace: string;
  active_pane_id: number;
  activity_time_stamp: string; // ISO; pick latest
}

interface WzPane {
  pane_id: number;
  tab_id: number;
  window_id: number;
  workspace: string;
  title: string;
  cwd: string; // file:// URL
}

function wzJson<T>(args: string[]): T {
  const out = execFileSync("wezterm", ["cli", ...args, "--format", "json"], {
    encoding: "utf8",
  });
  return JSON.parse(out) as T;
}

function wzList(): WzPane[] {
  return wzJson<WzPane[]>(["list"]);
}

function wzClients(): WzClient[] {
  try {
    return wzJson<WzClient[]>(["list-clients"]);
  } catch {
    return [];
  }
}

function focusedWorkspace(): string | null {
  const clients = wzClients();
  if (clients.length === 0) return null;
  const latest = clients.reduce((a, b) =>
    a.activity_time_stamp > b.activity_time_stamp ? a : b,
  );
  return latest.focused_workspace || null;
}

function uniqueWorkspaceName(base: string, existing: Set<string>): string {
  if (!existing.has(base)) return base;
  for (let i = 2; ; i++) {
    const candidate = `${base}-${i}`;
    if (!existing.has(candidate)) return candidate;
  }
}

export class WeztermBackend implements TerminalBackend {
  async openSession(sessionId: string, cwd: string, cmd: string[] = []) {
    const panes = wzList();
    const match = panes.find((p) => p.workspace === sessionId);
    if (match) {
      execFileSync("wezterm", [
        "cli",
        "activate-pane",
        "--pane-id",
        String(match.pane_id),
      ]);
      return;
    }
    spawn(
      "wezterm",
      [
        "cli",
        "spawn",
        "--workspace",
        sessionId,
        "--cwd",
        cwd,
        ...(cmd.length > 0 ? ["--", ...cmd] : []),
      ],
      { detached: true, stdio: "ignore" },
    ).unref();
  }

  async addTabToCurrent(cwd: string, cmd: string[] = []) {
    const ws = focusedWorkspace();
    if (!ws) {
      return this.openInNewWorkspace(basename(cwd) || "scratch", cwd, cmd);
    }
    spawn(
      "wezterm",
      [
        "cli",
        "spawn",
        "--workspace",
        ws,
        "--cwd",
        cwd,
        ...(cmd.length > 0 ? ["--", ...cmd] : []),
      ],
      { detached: true, stdio: "ignore" },
    ).unref();
  }

  async addPaneToCurrent(cwd: string, cmd: string[] = []) {
    spawn(
      "wezterm",
      [
        "cli",
        "split-pane",
        "--right",
        "--cwd",
        cwd,
        ...(cmd.length > 0 ? ["--", ...cmd] : []),
      ],
      { detached: true, stdio: "ignore" },
    ).unref();
  }

  async openInNewWorkspace(sessionId: string, cwd: string, cmd: string[] = []) {
    const panes = wzList();
    const existing = new Set(panes.map((p) => p.workspace));
    const name = uniqueWorkspaceName(sessionId, existing);
    spawn(
      "wezterm",
      [
        "cli",
        "spawn",
        "--workspace",
        name,
        "--cwd",
        cwd,
        ...(cmd.length > 0 ? ["--", ...cmd] : []),
      ],
      { detached: true, stdio: "ignore" },
    ).unref();
  }

  async listOpenProjects(_roots: string[]): Promise<OpenProject[]> {
    throw new Error("WeztermBackend.listOpenProjects implemented in stage 4");
  }
}
