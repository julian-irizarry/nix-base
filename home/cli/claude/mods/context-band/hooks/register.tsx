import { atom, read, update } from "claude-code";
import type {
  EngineInterface,
  Register,
  SessionContextUsage,
} from "claude-code";

import type { Fill } from "../types";

const fill = atom({ plugin: "context-band", key: "fill" } as const, null);

const PIE = ["○", "◔", "◑", "◕", "●"];
const CELLS = 10;

const fillOf = (c: SessionContextUsage): Fill | null =>
  c.tokens === undefined ? null : { tokens: c.tokens, window: c.window };

const refresh = async ($: EngineInterface) => {
  const f = fillOf((await $.session.usage()).context);
  await update($, fill, () => f);
  return f;
};

export const pieOf = (pct: number) =>
  PIE[
    Math.min(PIE.length - 1, Math.floor((pct / 100) * (PIE.length - 1) + 0.5))
  ];

export const barOf = (pct: number) => {
  const full = Math.min(CELLS, Math.round((pct / 100) * CELLS));
  return "▰".repeat(full) + "▱".repeat(CELLS - full);
};

export const label = (f: Fill) => {
  const pct = (f.tokens / f.window) * 100;
  return `${pieOf(pct)} ${barOf(pct)} ${pct.toFixed(2)}%`;
};

export const register: Register = (on) => {
  // TurnDuration rows carry no turn id, so each row is tied to the fill at the
  // turn end that preceded its first draw, keyed by its duration. Rows drawn
  // before this load have no entry and stay as the engine drew them.
  const byDuration = new Map<number, Fill>();
  let pending: Fill | null = null;

  on("session.start", async ($, e, next) => {
    const result = await next(e);
    await refresh($);
    return result;
  });

  on("session.measure", async ($, e, next) => {
    if (e.changed.includes("context"))
      await update($, fill, () => fillOf(e.context));
    return next(e);
  });

  // Main-thread steps only: a subagent's response would report its own window.
  on("turn.step", async function* ($, e, next) {
    const result = yield* next(e);
    if (!e.agentId) await refresh($);
    return result;
  });

  on("turn.complete", async ($, e, next) => {
    const result = await next(e);
    if (!e.agentId) pending = await refresh($);
    return result;
  });

  on("ui.render", { component: "Spinner" }, async ($, e, next) => {
    const f = await read($, fill);
    if (!f) return next(e);

    const { Box, Text } = $.ui.resolve(e);
    return (
      <Box flexDirection="row">
        <Box flexGrow={1}>{await next(e)}</Box>
        <Text dimColor>{label(f)}</Text>
      </Box>
    );
  });

  on("ui.render", { component: "TurnDuration" }, async ($, e, next) => {
    const ms = e.props.durationMs;
    let f = byDuration.get(ms);
    if (!f && pending) {
      f = pending;
      pending = null;
      byDuration.set(ms, f);
    }
    if (!f) return next(e);

    const { Box, Text } = $.ui.resolve(e);
    return (
      <Box flexDirection="row">
        <Box flexGrow={1}>{await next(e)}</Box>
        <Text dimColor>{label(f)}</Text>
      </Box>
    );
  });
};
