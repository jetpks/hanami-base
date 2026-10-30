import { act, fireEvent, render, screen } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import type { ReactNode } from 'react'

vi.mock('@inertiajs/react', () => ({
  Head: (_props: { title?: string }) => null,
}))

vi.mock('@/layouts/AppLayout', () => ({
  default: ({ children }: { children?: ReactNode }) => <div>{children}</div>,
}))

// jsdom ships no EventSource — a fake capturing instances is the observable
// surface this page needs: the URL it subscribes to, its handlers, and close().
class FakeEventSource {
  static instances: FakeEventSource[] = []
  url: string
  onopen: (() => void) | null = null
  onmessage: ((event: { lastEventId: string; data: string }) => void) | null = null
  onerror: (() => void) | null = null
  closed = false

  constructor(url: string) {
    this.url = url
    FakeEventSource.instances.push(this)
  }

  close() {
    this.closed = true
  }
}

const fetchMock = vi.fn()

import Index from './Index'

describe('Ticker/Index', () => {
  beforeEach(() => {
    FakeEventSource.instances = []
    vi.stubGlobal('EventSource', FakeEventSource)
    vi.stubGlobal('fetch', fetchMock)
    fetchMock.mockReset().mockResolvedValue({ ok: true })
  })

  afterEach(() => {
    vi.unstubAllGlobals()
  })

  it('subscribes to /ticker and goes live on open', () => {
    render(<Index />)
    const source = FakeEventSource.instances[0]
    expect(source.url).toBe('/ticker')
    expect(screen.getByText('connecting')).toBeTruthy()

    act(() => source.onopen?.())
    expect(screen.getByText('live')).toBeTruthy()
  })

  it('prepends a rendered tick for each received event', () => {
    render(<Index />)
    const source = FakeEventSource.instances[0]

    act(() => {
      source.onmessage?.({ lastEventId: '1776700000000-1', data: '{"type":"tick","n":3}' })
      source.onmessage?.({ lastEventId: '1776700000000-2', data: '{"type":"tick","n":4}' })
    })

    const items = screen.getAllByText(/^#/)
    expect(items.map((el) => el.textContent)).toEqual(['#4', '#3'])
    expect(screen.getByText('1776700000000-1')).toBeTruthy()
  })

  it('shows the retrying status line on a transport error', () => {
    render(<Index />)
    const source = FakeEventSource.instances[0]

    act(() => source.onerror?.())
    expect(screen.getByText('connection lost — retrying')).toBeTruthy()
  })

  it('closes the EventSource on unmount', () => {
    const { unmount } = render(<Index />)
    const source = FakeEventSource.instances[0]
    expect(source.closed).toBe(false)

    unmount()
    expect(source.closed).toBe(true)
  })

  it('publishes via fetch POST with the XSRF header', () => {
    document.cookie = 'XSRF-TOKEN=test-token'
    render(<Index />)

    fireEvent.click(screen.getByRole('button', { name: /send tick/i }))

    expect(fetchMock).toHaveBeenCalledWith('/ticker/publish', {
      method: 'POST',
      headers: { 'X-XSRF-TOKEN': 'test-token' },
    })
  })
})
