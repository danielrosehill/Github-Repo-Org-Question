# Prompt — Existing tool for auto-symlinking new repos

Date: 2026-04-09
Builds on: `outputs/individual/2026-04-09-db-backed-repo-manager.md`

## Context

The DB-backed approach is a build-your-own job. Stepping back: is there an **existing** tool that would give me:

1. A symlink automatically created when a new repo is born under `~/repos/github/`.
2. Symlinks for *folders* (groups) as well as individual repos, so I can bookmark the folder symlink in Dolphin and have it survive when the underlying grouping changes.
3. Some way of separating the symlink store into categories so I can target the right one (e.g. `~/repos/_links/claude-code/`, `~/repos/_links/clients/`).

Essentially: can I get the bookmark-survival benefit without building a custom tool?
