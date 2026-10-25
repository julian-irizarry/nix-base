export type Fill = { tokens: number; window: number }

declare module 'claude-code' {
  interface PluginState {
    'context-band': { fill: Fill | null }
  }
}
