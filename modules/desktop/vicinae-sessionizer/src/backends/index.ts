export interface OpenProject {
  cwd: string;
  workspace: string | null;
  tabTitle: string;
  clientId?: string;
}

export interface TerminalBackend {
  addTabToFocused(cwd: string, cmd?: string[]): Promise<void>;
  addPaneToFocused(cwd: string, cmd?: string[]): Promise<void>;
  createWorkspace(
    sessionId: string,
    cwd: string,
    cmd?: string[],
  ): Promise<void>;
  listOpenProjects(roots: string[]): Promise<OpenProject[]>;
  focusProject(project: OpenProject): Promise<void>;
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
