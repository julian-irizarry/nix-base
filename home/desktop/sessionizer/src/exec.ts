import { execFile, execFileSync, spawn } from "child_process";
import { promisify } from "util";
import { log } from "./log";

const execFileP = promisify(execFile);

export class CommandError extends Error {
  readonly cmd: string;
  readonly args: readonly string[];
  readonly code: number | null;
  readonly stderr: string;

  constructor(
    cmd: string,
    args: readonly string[],
    code: number | null,
    stderr: string,
    message?: string,
  ) {
    super(
      message ??
        `${cmd} ${args.join(" ")} failed (exit ${code ?? "?"}): ${stderr.trim()}`,
    );
    this.name = "CommandError";
    this.cmd = cmd;
    this.args = args;
    this.code = code;
    this.stderr = stderr;
  }
}

function normalizeStderr(err: unknown): string {
  if (err && typeof err === "object" && "stderr" in err) {
    const v = (err as { stderr: unknown }).stderr;
    if (typeof v === "string") return v;
    if (v instanceof Buffer) return v.toString("utf8");
  }
  return err instanceof Error ? err.message : String(err);
}

function normalizeCode(err: unknown): number | null {
  if (err && typeof err === "object" && "code" in err) {
    const v = (err as { code: unknown }).code;
    if (typeof v === "number") return v;
  }
  return null;
}

export interface ExecOpts {
  env?: NodeJS.ProcessEnv;
}

export function runSync(
  cmd: string,
  args: string[],
  opts: ExecOpts = {},
): string {
  const start = Date.now();
  try {
    const out = execFileSync(cmd, args, {
      encoding: "utf8",
      env: opts.env ?? process.env,
    });
    log.info("exec", "runSync ok", { cmd, args, ms: Date.now() - start });
    return out;
  } catch (err) {
    const stderr = normalizeStderr(err);
    const code = normalizeCode(err);
    log.error("exec", "runSync failed", {
      cmd,
      args,
      code,
      stderr,
      ms: Date.now() - start,
    });
    throw new CommandError(cmd, args, code, stderr);
  }
}

export async function runAsync(
  cmd: string,
  args: string[],
  opts: ExecOpts = {},
): Promise<string> {
  const start = Date.now();
  try {
    const { stdout } = await execFileP(cmd, args, {
      env: opts.env ?? process.env,
    });
    log.info("exec", "runAsync ok", { cmd, args, ms: Date.now() - start });
    return stdout;
  } catch (err) {
    const stderr = normalizeStderr(err);
    const code = normalizeCode(err);
    log.error("exec", "runAsync failed", {
      cmd,
      args,
      code,
      stderr,
      ms: Date.now() - start,
    });
    throw new CommandError(cmd, args, code, stderr);
  }
}

export function runAsyncWithStdin(
  cmd: string,
  args: string[],
  stdin: string,
  opts: ExecOpts = {},
): Promise<string> {
  const start = Date.now();
  return new Promise((resolve, reject) => {
    const child = spawn(cmd, args, {
      env: opts.env ?? process.env,
      stdio: ["pipe", "pipe", "pipe"],
    });
    let stdout = "";
    let stderr = "";
    child.stdout.on("data", (chunk) => {
      stdout += chunk.toString("utf8");
    });
    child.stderr.on("data", (chunk) => {
      stderr += chunk.toString("utf8");
    });
    child.on("error", (err) => {
      log.error("exec", "runAsyncWithStdin spawn error", {
        cmd,
        args,
        err: String(err),
      });
      reject(new CommandError(cmd, args, null, String(err)));
    });
    child.on("close", (code) => {
      if (code === 0) {
        log.info("exec", "runAsyncWithStdin ok", {
          cmd,
          args,
          ms: Date.now() - start,
        });
        resolve(stdout);
      } else {
        log.error("exec", "runAsyncWithStdin failed", {
          cmd,
          args,
          code,
          stderr,
          ms: Date.now() - start,
        });
        reject(new CommandError(cmd, args, code, stderr));
      }
    });
    child.stdin.write(stdin);
    child.stdin.end();
  });
}

export function runDetached(
  cmd: string,
  args: string[],
  opts: ExecOpts = {},
): void {
  log.info("exec", "runDetached", { cmd, args });
  spawn(cmd, args, {
    detached: true,
    stdio: "ignore",
    env: opts.env ?? process.env,
  }).unref();
}
