import { appendFileSync, mkdirSync } from "fs";
import { dirname, join } from "path";
import { homedir } from "os";

const LOG_DIR = join(
  process.env.XDG_STATE_HOME ?? join(homedir(), ".local", "state"),
  "vicinae-sessionizer",
);
const LOG_FILE = join(LOG_DIR, "sessionizer.log");

type Level = "debug" | "info" | "warn" | "error";

let initialized = false;

function writeLine(line: string): void {
  if (!initialized) {
    try {
      mkdirSync(dirname(LOG_FILE), { recursive: true });
    } catch {
      // best-effort
    }
    initialized = true;
  }
  try {
    appendFileSync(LOG_FILE, line + "\n");
  } catch {
    // never let logging crash the extension
  }
}

function safeStringify(v: unknown): string {
  try {
    return JSON.stringify(v);
  } catch {
    return String(v);
  }
}

function emit(level: Level, ns: string, msg: string, data?: unknown): void {
  const ts = new Date().toISOString();
  const body = data !== undefined ? `${msg} ${safeStringify(data)}` : msg;
  const line = `${ts} ${level.toUpperCase().padEnd(5)} [${ns}] ${body}`;
  writeLine(line);
  if (level === "error" || level === "warn") {
    console.error(line);
  } else {
    console.log(line);
  }
}

export const log = {
  debug: (ns: string, msg: string, data?: unknown) =>
    emit("debug", ns, msg, data),
  info: (ns: string, msg: string, data?: unknown) =>
    emit("info", ns, msg, data),
  warn: (ns: string, msg: string, data?: unknown) =>
    emit("warn", ns, msg, data),
  error: (ns: string, msg: string, data?: unknown) =>
    emit("error", ns, msg, data),
  time<T>(ns: string, action: string, fn: () => Promise<T>): Promise<T> {
    const start = Date.now();
    return fn().then(
      (result) => {
        emit("info", ns, `${action} ok`, { ms: Date.now() - start });
        return result;
      },
      (err) => {
        emit("error", ns, `${action} failed`, {
          ms: Date.now() - start,
          err: String(err),
        });
        throw err;
      },
    );
  },
  logFile: LOG_FILE,
};
