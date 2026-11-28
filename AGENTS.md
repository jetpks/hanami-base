# AGENTS.md

Working rules for agents (and humans) editing this repo. The README covers
architecture; this file covers how to work in it without review churn.

## Verification gates

Run all of these before calling work done — backend and frontend both gate:

```
bundle exec rake test      # Ruby suite (actions, repos, lib, integration)
npm run check              # tsc over both tsconfigs
npm test                   # vitest (frontend component tests)
npm run build              # production vite build sanity
```

## The frontend is composed, not accumulated

The rules in this section exist because agent-built pages — with every right
tool vendored and configured — still shipped as narrow columns of small gray
text. Having the primitives is not the same as using them.

### Pages are sections, not cards

- Every page renders inside `AppLayout` — never build your own nav or header.
  Pages choose their content width via `mainClassName` (default `max-w-5xl`
  for text; `max-w-6xl` for grids).
- Page shape: a **page header** (eyebrow, `h1`, lede; optional action button
  top-right — see `pages/Home/Index.tsx`) followed by content sections with
  consistent rhythm. A page that is just a `<Card>` floating top-left is a
  wireframe, not a page.
- Hierarchy comes from **scale contrast** (`text-xs` eyebrow → `text-4xl` h1
  → `text-lg` lede → `text-sm` body), never from more color. The `h1` is the
  page's one serif element (`font-heading`); all UI text stays sans.
- Color restraint: `primary` appears sparingly (eyebrows, icon chips, key
  actions). Everything else is neutral tokens.
- Repeated content is **data, not markup**: grids render an array through one
  card (see `FEATURES.map` in Home). Cards in a grid share identical internal
  anatomy so they align.

### Use the primitives — always

- **Never hand-style form controls.** No raw `<input className="rounded
  border px-2 py-1 ...">` — that pattern shipped 69 times before this rule
  existed. Use `components/ui/input`, `checkbox`, `textarea`, `select`, etc.
- Missing primitive? `npx shadcn@latest add <name> --overwrite`. It must
  land in `app/frontend/components/ui/` — the `@/*` alias lives in the ROOT
  `tsconfig.json`; if a literal `@/` directory appears at the repo root, the
  alias resolution broke and every file under it is misplaced.
- Icons: `lucide-react`, `XIcon`-suffix imports, `size-4` inside components.
- Both `cn` (npm) and `@/lib/utils` are valid class-merge helpers — new
  registry code imports `cn`; don't churn old files to unify.

### Every screen designs four states

Loading, empty, error, success — each rendered, not implied. A
happy-path-only screen is incomplete work. Live feeds additionally show
connection status (see `pages/Ticker/Index.tsx`).

### Flash is toasts, not paragraphs

Flash messages surface through sonner via `AppLayout` (StrictMode-guarded).
Pages never render `flash` themselves.

## The shadcn model (read before vendoring)

- `components/ui/*` is **vendored, owned code** — edit it freely; there is no
  upgrade path by design. To see registry drift for one file:
  `npx shadcn@latest add <name> --diff`.
- `npx shadcn@latest add <block>` (e.g. `sidebar-07`, `dashboard-01`)
  vendors composed examples with demo content. **Adapt after adding:**
  strip sample data, wire real props and Inertia links, delete files you
  don't use. `ui/*` = generic primitives (don't customize per-page);
  `components/*` = app-specific composition (yours to rewrite).
- Theming is tokens in `application.css`, changed wholesale via the shadcn
  generator (`ui.shadcn.com/create`) + `npx shadcn@latest apply <code>
  --only theme,font` — never per-component. Never hardcode colors: use
  semantic tokens (`bg-primary`, `text-muted-foreground`, `border-border`).
  Chart series use `--chart-1..5`.
- Interaction affordances must tell the truth: click-only controls get
  `cursor-pointer`, not resize cursors; anything draggable says so.

## Inertia + SSE discipline

- Pages live at `app/frontend/pages/<Name>/Index.tsx` and map 1:1 to the
  component name an action passes to `render_inertia`. Props come only from
  the server; fetch nothing client-side that the action can pass.
- **Test the page route, not just the pipe.** Every page needs an action
  test asserting the page object (component name, url, shared props) — see
  `test/actions/ticker_test.rb`. The ticker page once shipped unroutable
  (the SSE route answered every request) with the whole suite green because
  the transport was tested and the page render was not.
- A live feed is **two routes**: the page (`GET /x`, Inertia) and the
  stream (`GET /x/stream`, EventSource). Never one route for both; see
  `Actions::Ticker::{Index,Stream}`.

## Backend conventions

Follow the existing patterns over inventing new ones: dry-rb operations
under `app/operations`, ROM relations under `app/relations`, actions stay
thin and render via `render_inertia` / `render_json` / `render_stream`.
SSE actions subclass `Template::StreamAction` and gate in `handle` BEFORE
`render_stream` — after the SSE headers are set, errors can only surface
as a broken stream.
