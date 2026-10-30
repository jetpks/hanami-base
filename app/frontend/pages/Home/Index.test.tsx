import { render } from '@testing-library/react'
import { describe, expect, it, vi } from 'vitest'
import type { ReactNode } from 'react'
import type { SharedProps } from '@/types'

// usePage returns this object by reference, so the per-test shared props are
// written into it before each render.
const props: SharedProps = { current_user: null, flash: {} }

vi.mock('@inertiajs/react', () => ({
  Head: (_props: { title?: string }) => null,
  usePage: () => ({ props }),
}))

vi.mock('@/layouts/AppLayout', () => ({
  default: ({ children }: { children?: ReactNode }) => <div>{children}</div>,
}))

import Index from './Index'

function renderPage(shared: Partial<SharedProps> = {}) {
  props.current_user = shared.current_user ?? null
  props.flash = shared.flash ?? {}
  return render(<Index />)
}

describe('Home/Index', () => {
  it('shows the app name', () => {
    const { container } = renderPage()
    expect(container.textContent).toContain('Hanami Base')
  })

  it('shows the signed-in user name', () => {
    const { container } = renderPage({ current_user: { id: 1, username: 'alice', avatar_url: null } })
    expect(container.textContent).toContain('alice')
  })

  it('shows a sign-in nudge when anonymous', () => {
    const { container } = renderPage()
    expect(container.textContent).toContain('Sign in')
  })

  it('shows flash notices and alerts', () => {
    const { container } = renderPage({ flash: { notice: 'Signed in.', alert: 'Watch out.' } })
    expect(container.textContent).toContain('Signed in.')
    expect(container.textContent).toContain('Watch out.')
  })
})
