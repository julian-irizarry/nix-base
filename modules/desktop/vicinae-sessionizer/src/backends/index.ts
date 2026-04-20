export interface OpenSession {
  workspace: string;
}

export interface TerminalBackend {
  addTabToFocused(cwd: string, cmd?: string[]): Promise<void>;
  addPaneToFocused(cwd: string, cmd?: string[]): Promise<void>;
  createWorkspace(
    sessionId: string,
    cwd: string,
    cmd?: string[],
  ): Promise<void>;
  listOpenSessions(): Promise<OpenSession[]>;
  focusSession(session: OpenSession): Promise<void>;
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
