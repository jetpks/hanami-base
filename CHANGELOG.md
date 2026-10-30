# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- Attachments + background-jobs substrate: the Shrine uploader skeleton
  (`Template::AttachmentUploader` — memory storages in test, file-system
  otherwise, uploader JSON in a text column with `uploaded_file`
  reconstitution from the struct) and the async-job queue (Inline processor in
  test, redis processor + `bin/worker` otherwise, one shared
  `build_redis_processor` construction), proven end-to-end by the documents
  example (`POST /documents` → `Template::Jobs::ProcessDocument` records
  the attachment's byte size).
- SSE transport substrate: `Template::StreamAction` (the three SSE
  headers, streaming proc body, subscribe-then-backlog race discipline with
  numeric entry-id dedup, heartbeat-on-pop-timeout, Last-Event-ID resume) over
  redis streams via `Template::SSE` + `SSE::Fanout` (`lib/template/`),
  with the public ticker example (`GET /ticker` live feed +
  `POST /ticker/publish`, `Ticker/Index` page) and the restored redis test
  posture (suite-boot guard + FLUSHDB, CI `redis:7` service).

### Changed

- Renamed the module namespace and every identifier derived from it to the
  `Template` placeholder — the session cookie key (`_template_session`), the
  credentials master-key env var (`TEMPLATE_MASTER_KEY`), the
  `template_development`/`template_test` databases (`.env`, `.env.test`, CI),
  the npm name, the `template.web` falcon service, the display strings, and
  `lib/template/` — collapsing the two-level seed nesting to the framework's
  single-level convention. Added the mint flow (`bin/bootstrap` + the README
  mint section) that renames a fresh clone to a real project and verifies
  itself grep-clean.

## [0.1.0] - 2026-10-30

### Added

- hanami-base: the base Hanami application template, minted as a fresh-history
  tree copy of [all-fax-no-printer](https://github.com/jetpks/all-fax-no-printer)
  @ `3b42334` (seed commit `34eba87`) and distilled to the template substrate:
  the observation-deck domain was cut wholesale and the three places it was
  load-bearing were re-seamed — OAuth provider config is settings-driven
  (`oauth_providers`), sign-in authorization is a policy seam
  (`app/operations/authorize_user.rb`, default allow), and CI carries the
  fast-llm shape minus publishing/dependabot. Lineage: all-fax-no-printer is
  the `server/` subtree of the space-architect monorepo, itself descended from
  a fork of [jetpks/chat_share](https://github.com/jetpks/chat_share).
