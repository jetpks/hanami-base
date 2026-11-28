import { Head, Link, usePage } from '@inertiajs/react'
import {
  ActivityIcon,
  DatabaseIcon,
  HeartPulseIcon,
  KeyRoundIcon,
  LayoutTemplateIcon,
  PaletteIcon,
  WorkflowIcon,
} from 'lucide-react'
import type { ReactNode } from 'react'

import {
  Card,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import AppLayout from '@/layouts/AppLayout'
import type { SharedProps } from '@/types'

// The template's example page: exercises the whole chain — shared props
// (current_user), the vite CSS pipeline, and the components/ui primitives —
// while demonstrating the composition patterns a minted project starts from:
// a page header with real hierarchy, a feature card grid, and section rhythm.
// No domain vocabulary; a project replaces this content with its own.

// Feature cards are data, not markup — the grid renders whatever the minted
// project writes here.
const FEATURES: {
  icon: ReactNode
  title: string
  description: ReactNode
}[] = [
  {
    icon: <DatabaseIcon className="size-4" />,
    title: 'Typed backend',
    description:
      'Hanami 3 actions, ROM-SQL relations, dry-rb validation and operations, cookie sessions.',
  },
  {
    icon: <KeyRoundIcon className="size-4" />,
    title: 'GitHub OAuth',
    description:
      'OmniAuth sign-in with the authorize_user policy seam, and CSP wired to the enabled providers.',
  },
  {
    icon: <ActivityIcon className="size-4" />,
    title: 'Live transport',
    description: (
      <>
        SSE streaming with heartbeats and Last-Event-ID resume —{' '}
        <Link
          href="/ticker"
          className="font-medium text-primary underline-offset-4 hover:underline"
        >
          watch it live on the Ticker page
        </Link>
        .
      </>
    ),
  },
  {
    icon: <WorkflowIcon className="size-4" />,
    title: 'Background jobs',
    description:
      'async-job with the Inline processor in test and a redis processor otherwise, one shared construction.',
  },
  {
    icon: <LayoutTemplateIcon className="size-4" />,
    title: 'This frontend',
    description:
      'Inertia + Vite + React + Tailwind + shadcn, pre-composed into the application shell you are looking at.',
  },
  {
    icon: <HeartPulseIcon className="size-4" />,
    title: 'Ops baked in',
    description:
      'Encrypted credentials, a /up healthcheck, force-SSL, and falcon serving under bin/serve.',
  },
]

export default function Index() {
  const { current_user } = usePage<SharedProps>().props

  return (
    <AppLayout mainClassName="max-w-6xl">
      <Head title="Home" />

      <div className="space-y-10 py-6">
        {/* Page header — the top of every composed page: eyebrow / heading /
            lede on the left, actions on the right. The h1 is the only serif
            element on the page; hierarchy comes from scale contrast (eyebrow
            → h1 → lede), not from color. */}
        <header className="flex flex-col gap-6 sm:flex-row sm:items-start sm:justify-between">
          <div className="space-y-3">
            <p className="text-xs font-semibold tracking-widest text-primary uppercase">
              hanami-base
            </p>
            <h1 className="font-heading text-4xl font-semibold tracking-tight">
              Template
            </h1>
            <p className="max-w-2xl text-lg text-muted-foreground">
              A clone-and-go Hanami 3 application template: the harness and
              transport every project wants, and no domain. Every new project
              is minted from here.
            </p>
            <p className="text-sm text-muted-foreground">
              {current_user ? (
                <>
                  Signed in as{' '}
                  <span className="font-medium text-foreground">
                    {current_user.username}
                  </span>{' '}
                  — the auth chain has round-tripped.
                </>
              ) : (
                <>
                  Sign in with the GitHub button in the header to round-trip
                  the auth chain.
                </>
              )}
            </p>
          </div>

          {/* The mint workflow's first move: re-skin the template in the
              shadcn theme generator, then `npx shadcn apply <code> --only
              theme,font` — tokens only, no component churn. */}
          <div className="shrink-0">
            <Button variant="outline" asChild>
              <a
                href="https://ui.shadcn.com/create"
                target="_blank"
                rel="noreferrer"
              >
                <PaletteIcon /> Customize the theme
              </a>
            </Button>
          </div>
        </header>

        {/* Feature grid — the middle section: consistent gaps, cards that
            align because they all share the same internal structure. */}
        <section className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {FEATURES.map((feature) => (
            <Card key={feature.title}>
              <CardHeader>
                <CardTitle className="flex items-center gap-2 text-base">
                  <span className="flex size-8 shrink-0 items-center justify-center rounded-lg bg-primary/10 text-primary">
                    {feature.icon}
                  </span>
                  {feature.title}
                </CardTitle>
                <CardDescription className="text-sm leading-relaxed">
                  {feature.description}
                </CardDescription>
              </CardHeader>
            </Card>
          ))}
        </section>
      </div>
    </AppLayout>
  )
}
