import { readFileSync, writeFileSync, mkdirSync } from "fs";
import { join, dirname } from "path";
import { homedir } from "os";

export type Mode = "shell" | "nvim";

const STATE_FILE = join(
  process.env.XDG_STATE_HOME ?? join(homedir(), ".local", "state"),
  "vicinae-sessionizer",
  "mode.json",
);

export function loadMode(): Mode {
  try {
    const parsed = JSON.parse(readFileSync(STATE_FILE, "utf8"));
    return parsed.mode === "nvim" ? "nvim" : "shell";
  } catch {
    return "shell";
  }
}

export function saveMode(mode: Mode): void {
  mkdirSync(dirname(STATE_FILE), { recursive: true });
  writeFileSync(STATE_FILE, JSON.stringify({ mode }));
}
