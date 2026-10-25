import { expect, test } from 'claude-code/testing'

import { segmentsOf } from '../hooks/register'

const REPLY = (text: string, requestId = 'm1') =>
  ({
    plugin: 'code-cards',
    component: 'AssistantMessage',
    requestId,
    surface: 'terminal',
    props: { text, isFirstOfReply: true },
  }) as const

const engine = (on: Parameters<Parameters<typeof test>[1]>[1]) =>
  on('ui.render', ($, e) => {
    const { Text } = $.ui.resolve(e)
    return <Text>engine</Text>
  })

test('splits prose and fenced code, keeping the language', () => {
  const s = segmentsOf('Before\n\n```go\nfmt.Println("hi")\n```\n\nAfter')
  expect(s).toEqual([
    { kind: 'prose', text: 'Before' },
    { kind: 'code', lang: 'go', code: 'fmt.Println("hi")' },
    { kind: 'prose', text: 'After' },
  ])
})

test('tilde fences, no language, and an unclosed fence while streaming', () => {
  expect(segmentsOf('~~~\na\n~~~')).toEqual([{ kind: 'code', lang: '', code: 'a' }])
  expect(segmentsOf('x\n```sh\nls\npw')).toEqual([
    { kind: 'prose', text: 'x' },
    { kind: 'code', lang: 'sh', code: 'ls\npw' },
  ])
})

test('a shorter fence inside a longer one stays code', () => {
  expect(segmentsOf('````md\n```js\nx\n```\n````')).toEqual([{ kind: 'code', lang: 'md', code: '```js\nx\n```' }])
})

test('a reply with no code is left to the engine', async ($, on) => {
  engine(on)
  const ui = await $.ui.mount(REPLY('just prose, `inline` too'))
  expect((await ui.find({ type: 'Text', text: /engine/ }))?.text).toBe('engine')
  await ui.unmount()
})

test('a code block is a card with its language and a copy icon that copies the code', async ($, on) => {
  engine(on)
  const copied: string[] = []
  on('ui.copy', (_, e) => {
    copied.push(e.text)
    return { value: { isCopied: true } }
  })
  on('ui.toast', () => ({ value: undefined }))

  const ui = await $.ui.mount(REPLY('Run this:\n\n```bash\necho hi\n```'))
  expect(await ui.find({ type: 'Text', text: /engine/ })).toBeUndefined()
  expect((await ui.find({ type: 'Text', text: / bash / }))?.text).toBe(' bash ')
  expect(await ui.find({ type: 'Markdown' })).toBeDefined()
  expect((await ui.find({ type: 'Code' }))?.props).toMatchObject({ source: 'echo hi', language: 'bash' })
  expect(await ui.findAll({ type: 'Button' })).toHaveLength(1)

  await ui.press({ key: 'copy-0' })
  expect(copied).toEqual(['echo hi'])
  await ui.unmount()
})

test('speed: parsing and drawing a large reply', async ($, on) => {
  engine(on)
  const block = 'Some prose line with **bold** and a list\n- a\n- b\n\n```ts\n' + 'const x = 1\n'.repeat(40) + '```\n\n'
  const big = block.repeat(100) // about 60 KB, 100 code blocks

  let t = Date.now()
  for (let i = 0; i < 20; i++) segmentsOf(big)
  const parseMs = (Date.now() - t) / 20

  t = Date.now()
  const ui = await $.ui.mount(REPLY(big, 'big'))
  const firstDrawMs = Date.now() - t
  await ui.unmount()

  t = Date.now()
  const small = await $.ui.mount(REPLY('x\n```sh\nls\n```', 'small'))
  const smallDrawMs = Date.now() - t
  await small.unmount()

  console.log(`parse ${big.length} chars: ${parseMs.toFixed(2)}ms; draw big: ${firstDrawMs}ms; draw small: ${smallDrawMs}ms`)
  expect(parseMs).toBeLessThan(20)
})
