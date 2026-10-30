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
- SSE transport substrate: `Template::StreamAction` (streaming body,
  heartbeat, Last-Event-ID resume, subscribe-then-backlog race discipline)
  over redis streams (`Template::SSE` + `SSE::Fanout` in
  `lib/template/`), proven end-to-end by the public ticker example
  (`GET /ticker` live feed + `POST /ticker/publish`, `Ticker/Index` page).
- Attachments: a Shrine uploader skeleton (`Template::AttachmentUploader`)
  with memory storages in test / file-system otherwise, the uploader JSON in a
  text column, and `uploaded_file` reconstitution from the struct.
- Background jobs: async-job with the Inline processor in test / a redis
  processor otherwise, plus the `bin/worker` dev worker — enqueued and processed
  through one shared construction.
- Five in-tree gems under `gems/` (frozen substrate): hanami-credentials,
  hanami-force-ssl, hanami-healthcheck, inertia-hanami, vite-hanami.
- mise ruby pin, healthcheck (`GET /up`), force-ssl, encrypted credentials.

## The two seams a project configures

### OAuth providers (settings-driven)

`config/settings.rb` exposes `oauth_providers` (default `["github"]`; accepts a
comma-separated string for ENV overrides). `config/app.rb` maps each enabled
name through the `Template::OAUTH_PROVIDERS` table to its OmniAuth
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

## The SSE transport

Actions that stream live events subclass `Template::StreamAction`
(`app/stream_action.rb`) and call `render_stream(req, res, key:)` with a redis
stream key. The response carries the three SSE headers, replays the stream's
backlog (a reconnecting client's `Last-Event-ID` becomes the exclusive start
bound), then live-tails the key with a 15s heartbeat comment until the client
disconnects. Entries are redis stream `[entry_id, fields]` pairs framed as
`id:`/`data:` lines; the numeric entry-id cursor deduplicates the race window
between subscribing and reading the backlog (`lib/template/sse.rb`).

The transport carries no auth machinery by design — gating is the subclass's
job: override `handle`, do the check FIRST, and only then call `render_stream`
(halting before it keeps the error response ordinary JSON; once the SSE headers
are set, an error can only surface as a broken stream).

The ticker example is the whole chain in miniature: `GET /ticker` (the
`Ticker/Index` page's `EventSource`) tails the `sse:ticker` stream, and
`POST /ticker/publish` (the page's fetch POST carrying `X-XSRF-TOKEN`) INCRs a
counter and XADDs one capped entry.

Redis is required for the transport. Dev reads `REDIS_URL` (falling back to
localhost db 0); the test suite boots against an isolated non-zero database and
flushes it — `test/test_helper.rb` raises otherwise, so a misconfigured suite
fails loudly instead of wiping dev.

## Attachments and background jobs

Uploads go through `Template::AttachmentUploader`
(`app/attachment_uploader.rb`): `AttachmentUploader.store(io)` uploads to the
`store` storage and returns the JSON string a text column carries
(`{id, storage, metadata}`); the struct's `#attachment` reconstitutes it into
an `UploadedFile` (`.open { |io| ... }`, `.each_line`, `.metadata`) and is nil
when the column is empty. Storages are configured at class load — in-memory in
test (nothing on disk, nothing to clean up), `storage/{cache,store}` under the
app root in dev/prod (git-ignored).

Background work is enqueued through the `job_queue` dep
(`config/providers/job_queue.rb`): under test it is
`Async::Job::Processor::Inline` and the job body runs in-request; otherwise it
is a redis-backed processor and a worker process dequeues:

```sh
REDIS_URL=redis://localhost:6379 mise exec -- bundle exec ruby bin/worker.rb
```

The worker and the tests share one construction —
`Jobs::ProcessDocument.build_redis_processor(prefix:)` — so the queue a test
round-trips against is exactly the one the worker runs; tests pass a unique
prefix per run so they never touch a live worker's keys.

The `documents` table is the copy-me example: `POST /documents`
(`Actions::Documents::Create`) stores the upload, persists the JSON, and
enqueues `{"document_id" => id}`; `Jobs::ProcessDocument`
(`app/jobs/process_document.rb`) opens the attachment, records its byte size
and `processed_at`, and returns early (warn, never raise) when the row or its
attachment is gone.

## Mint a project

Clone this repo (or copy the tree) and develop — it boots as-is under the
placeholder module, so the harness is usable before any renaming. To mint it
as a real project:

```sh
ruby bin/bootstrap <NewName>          # one CamelCase word, e.g. AcmeCorp
mise exec -- bundle exec hanami db prepare   # creates the renamed databases
npm ci --no-fund --no-audit
```

`bin/bootstrap` renames the module and every identifier derived from it —
the session cookie key, the credentials master-key env var, the database
names (`.env`, `.env.test`, CI), the npm name, the falcon service, the
display strings, and the `lib/` paths — then re-greps the whole tree for
every one of them and removes itself: a minted project carries no template
tooling, and the script's own pattern strings are the tokens it sweeps.
Multiword names go kebab where the platform requires it (`AcmeCorp` → npm
`acme-corp`, falcon `acme-corp.web`) and snake everywhere else
(`acme_corp_test`, `ACME_CORP_MASTER_KEY`).

Then two steps the script can't do: name the repo / set its remote, and read
this README through — it still describes the substrate, not your project.
`gems/**` are deliberately untouched; their namespaces are their own.

Two carry-overs are name-only-faithful to the template and stay as-is: the
provider-keyed `users.github_uid` column, and the github OAuth `read:org`
scope in `config/app.rb`. Both predate the authorization seam — a project
with its own authz rule may want to revisit them (see
[the two seams](#the-two-seams-a-project-configures)).

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

The background-jobs worker is a separate dev-only process (see
[Attachments and background jobs](#attachments-and-background-jobs)):

```sh
REDIS_URL=redis://localhost:6379 mise exec -- bundle exec ruby bin/worker.rb
```

## Test

```sh
bundle exec rake test  # Ruby suite (needs local postgres + redis; mise exec -- wraps ruby)
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
