export interface OpenProject {
  cwd: string;
  workspace: string | null;
  tabTitle: string;
  clientId?: string;
}

export interface TerminalBackend {
  openSession(sessionId: string, cwd: string, cmd?: string[]): Promise<void>;
  addTabToCurrent(cwd: string, cmd?: string[]): Promise<void>;
  addPaneToCurrent(cwd: string, cmd?: string[]): Promise<void>;
  openInNewWorkspace(
    sessionId: string,
    cwd: string,
    cmd?: string[],
  ): Promise<void>;
  listOpenProjects(roots: string[]): Promise<OpenProject[]>;
}

export type BackendName = "wezterm" | "kitty";

export async function getBackend(name: BackendName): Promise<TerminalBackend> {
  switch (name) {
    case "kitty": {
      const { KittyBackend } = await import("./kitty");
      return new KittyBackend();
    }
    case "wezterm": {
      const { WeztermBackend } = await import("./wezterm");
      return new WeztermBackend();
    }
  }
}
