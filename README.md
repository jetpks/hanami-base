# hanami-base

The base Hanami application template: a clone-and-go substrate for new
projects. Every new project is minted from this repo — it carries the harness
and transport every project wants and no domain.

## What's in the box

- Hanami 3.0.x + falcon (supervised topology via `bin/serve` → `falcon.rb`),
  ROM-SQL/postgres, the dry-rb suite (types, validation, monads, operations),
  cookie sessions.
- OmniAuth OAuth with GitHub as the compiled-in example strategy (see the
  provider seam below).
- Full frontend kit: Vite + React + Inertia + Tailwind 4 + shadcn/radix
  primitives, layout/nav scaffold, and one example page (`Home/Index` at `/`)
  exercising the whole chain — inertia shared props, the vite pipeline, and a
  `components/ui` primitive.
- Five in-tree gems under `gems/` (frozen substrate): hanami-credentials,
  hanami-force-ssl, hanami-healthcheck, inertia-hanami, vite-hanami.
- mise ruby pin, healthcheck (`GET /up`), force-ssl, encrypted credentials.

## The two seams a project configures

### OAuth providers (settings-driven)

`config/settings.rb` exposes `oauth_providers` (default `["github"]`; accepts a
comma-separated string for ENV overrides). `config/app.rb` maps each enabled
name through the `Space::Server::OAUTH_PROVIDERS` table to its OmniAuth
strategy registration (client credentials from settings) and derives the CSP
`form-action` origins from the same list. A provider name missing from the map
raises at boot. Adding a provider = strategy gem + one map entry + settings
flip.

### Sign-in authorization

`app/operations/authorize_user.rb` is the policy seam consulted by
`sessions.create` between authentication and session creation. The default
allows any authenticated identity — the template must round-trip auth out of
the box. A project overrides `#call(user, auth_hash)` (the OmniAuth auth hash
carries the provider's own claims: orgs, teams, email domain) to plug its own
rule; a `false` outcome redirects to `/` with an alert flash and no session.

## Mint a project

Clone this repo and develop — it boots as-is. (A rename/mint pass for the
`Space::Server` module, session key, and database names is planned tooling;
until then those names are the template's own.)

## Setup

```sh
bundle install
npm install
```

Credentials are managed via Hanami's encrypted credentials store:

```sh
bin/credentials edit   # opens $EDITOR; set github_client_id/secret and db url
```

## Run

```sh
bin/dev   # starts web server (:3000) and Vite (:3036)
```

## Test

```sh
bundle exec rake test  # Ruby suite (needs local postgres; mise exec -- wraps ruby)
npm test               # Vitest (TypeScript/component tests)
npm run check          # TypeScript type check
```

CI (.github/workflows/ci.yml) runs the same three plus a per-gem suite matrix
for the five in-tree gems and a non-blocking bundler-audit.

## Provenance

Distilled from
[all-fax-no-printer](https://github.com/jetpks/all-fax-no-printer) @ `3b42334`
(seed commit `34eba87`, fresh git history) — itself the `server/` subtree of
the space-architect monorepo, descended from a fork of `jetpks/chat_share`.
See [CHANGELOG.md](CHANGELOG.md).
