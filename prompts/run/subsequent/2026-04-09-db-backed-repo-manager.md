# Prompt — DB-backed repo manager with semantic search

Date: 2026-04-09
Builds on: `outputs/individual/2026-04-09-repo-org-and-portability.md`

## Context

Filesystem-based organisation feels too brittle at the volume of GitHub repos I manage. I want something more robust.

## Use case

1. I create a new repo in GitKraken → `~/repos/github/new-project1` appears.
2. A watcher should detect this "on birth" and register it in a local index, auto-creating a symlink / entry.
3. The organisational structure (tags, groups, notes) lives in a version-controlled store, not the filesystem, so moves don't break anything.
4. I want **fast semantic search** over repos — by name, README content, topic, tags — and from the results, one-click:
   - open a terminal at the repo
   - open Claude Code at the repo
   - open in a file manager (Dolphin)
   - open in GitKraken / VS Code

## Question

Are there existing local-database-backed repo manager tools that fit this? If not, what's the right stack to build one (watcher + SQLite/DuckDB + embeddings + launcher UI)? Keep it Linux/KDE-friendly.
