# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

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
