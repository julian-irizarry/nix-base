import { readFileSync, existsSync } from "fs";
import { join } from "path";
import { homedir } from "os";
import type { BackendName } from "./backends";

const CONFIG_FILE = join(homedir(), ".config", "vicinae", "sessionizer.json");

export interface Config {
  roots: string[];
  terminal: BackendName;
}

const DEFAULT_CONFIG: Config = {
  roots: [join(homedir(), "sources")],
  terminal: "wezterm",
};

export function loadConfig(): Config {
  try {
    const raw = readFileSync(CONFIG_FILE, "utf8");
    const parsed = JSON.parse(raw);
    const roots = Array.isArray(parsed.roots)
      ? parsed.roots
          .filter((r: unknown): r is string => typeof r === "string")
          .map((r: string) => r.replace(/^~/, homedir()))
          .filter(existsSync)
      : DEFAULT_CONFIG.roots;
    const terminal: BackendName =
      parsed.terminal === "kitty" || parsed.terminal === "wezterm"
        ? parsed.terminal
        : DEFAULT_CONFIG.terminal;
    return { roots, terminal };
  } catch {
    return {
      ...DEFAULT_CONFIG,
      roots: DEFAULT_CONFIG.roots.filter(existsSync),
    };
  }
}
