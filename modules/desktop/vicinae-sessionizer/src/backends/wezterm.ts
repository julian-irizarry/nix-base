import type { TerminalBackend, OpenProject } from "./index";

export class WeztermBackend implements TerminalBackend {
  async openSession(_sessionId: string, _cwd: string, _cmd: string[] = []) {
    throw new Error("WeztermBackend not implemented yet (stage 3)");
  }
  async addTabToCurrent(_cwd: string, _cmd: string[] = []) {
    throw new Error("WeztermBackend not implemented yet (stage 3)");
  }
  async addPaneToCurrent(_cwd: string, _cmd: string[] = []) {
    throw new Error("WeztermBackend not implemented yet (stage 3)");
  }
  async openInNewWorkspace(
    _sessionId: string,
    _cwd: string,
    _cmd: string[] = [],
  ) {
    throw new Error("WeztermBackend not implemented yet (stage 3)");
  }
  async listOpenProjects(_roots: string[]): Promise<OpenProject[]> {
    throw new Error("WeztermBackend not implemented yet (stage 3)");
  }
}
