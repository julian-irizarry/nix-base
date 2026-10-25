import type { Register } from 'claude-code'

export type Segment = { kind: 'prose'; text: string } | { kind: 'code'; lang: string; code: string }

// nf-md-content_copy
const COPY_ICON = ' \u{F018F} '
const FENCE = /^ {0,3}(`{3,}|~{3,})\s*([^\s`]*)/
const CACHE_MAX = 200

const trimBlankLines = (s: string) => s.replace(/^(?:[ \t]*\n)+/, '').replace(/(?:\n[ \t]*)+$/, '')

// One pass over the lines. An unclosed fence (a reply still streaming) runs to the end.
export const segmentsOf = (text: string): Segment[] => {
  const out: Segment[] = []
  const lines = text.split('\n')
  let prose: string[] = []
  let i = 0

  const flushProse = () => {
    const t = trimBlankLines(prose.join('\n'))
    if (t) out.push({ kind: 'prose', text: t })
    prose = []
  }

  while (i < lines.length) {
    const line = lines[i]!
    const open = FENCE.exec(line)
    if (!open) {
      prose.push(line)
      i++
      continue
    }

    const marker = open[1]!
    const fenceChar = marker[0]!
    const lang = open[2] ?? ''
    const code: string[] = []
    i++
    while (i < lines.length) {
      const l = lines[i]!
      const t = l.trimStart()
      if (l.length - t.length <= 3 && t.startsWith(marker) && t.replace(new RegExp(`^\\${fenceChar}+`), '').trim() === '') break
      code.push(l)
      i++
    }
    i++
    flushProse()
    out.push({ kind: 'code', lang, code: code.join('\n').replace(/\t/g, '    ') })
  }
  flushProse()
  return out
}

export const register: Register = on => {
  // Per message, the last text parsed: a scroll or resize re-runs the hook on the same text.
  const cache = new Map<string, { text: string; segments: Segment[] }>()

  const cachedSegments = (id: string, text: string) => {
    const hit = cache.get(id)
    if (hit && hit.text === text) return hit.segments
    const segments = segmentsOf(text)
    cache.delete(id)
    cache.set(id, { text, segments })
    if (cache.size > CACHE_MAX) cache.delete(cache.keys().next().value!)
    return segments
  }

  on('ui.render', { component: 'AssistantMessage' }, ($, e, next) => {
    const { text, isSummary, isFirstOfReply } = e.props
    if (e.surface !== 'terminal' || isSummary || (!text.includes('```') && !text.includes('~~~'))) return next(e)

    const segments = cachedSegments(e.requestId, text)
    if (!segments.some(s => s.kind === 'code')) return next(e)

    const { Box, Text, Markdown, Button, Code } = $.ui.resolve(e)
    const copy = (code: string) => {
      void $.ui.copy({ text: code, surface: e.surface }).then(r => $.ui.toast(r.isCopied ? 'Copied' : 'Could not copy here'))
    }

    let n = 0
    const rows = segments.map(s => {
      if (s.kind === 'prose') return <Markdown text={s.text} />
      const id = n++
      return (
        <Box flexDirection="column">
          <Box flexDirection="column" borderStyle="round" borderColor="gray" borderDimColor paddingX={1}>
            <Code source={s.code || ' '} language={s.lang || undefined} />
          </Box>
          {s.lang ? (
            <Box position="absolute" top={0} left={2}>
              <Text dimColor>{` ${s.lang} `}</Text>
            </Box>
          ) : (
            ''
          )}
          <Box position="absolute" top={0} right={2}>
            <Button key={`copy-${id}`} plain dimColor label={COPY_ICON} onPress={() => copy(s.code)} />
          </Box>
        </Box>
      )
    })

    return (
      <Box flexDirection="row">
        <Box width={2} flexShrink={0}>
          <Text>{isFirstOfReply ? '●' : ' '}</Text>
        </Box>
        <Box flexDirection="column" flexGrow={1} flexShrink={1}>
          {rows}
        </Box>
      </Box>
    )
  })
}
