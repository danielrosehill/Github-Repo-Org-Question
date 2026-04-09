# Prompt — Existing "GitHub repo fleet manager" tools

Date: 2026-04-09
Builds on: `outputs/individual/2026-04-09-search-first-launcher.md`

## Context

This feels like a common enough problem that a tool should exist. Expanding the requirements beyond search + launcher:

## Bulk / lifecycle operations I want

- Delete a repo locally
- Delete a repo on the remote (GitHub)
- Delete both at once
- Pull down (clone) repos I haven't cloned yet
- Bulk pull / fetch across many clones
- See which local clones are stale vs. remote
- See which remote repos have no local clone
- See which local clones are orphans (not on remote anymore)

## UX requirements

- **Fuzzy search** is essential
- **MRU (most recently used) auto-populated list** at the top
- **Favourites** list (manual pin for the ~10 daily repos)
- MRU + favourites + search together probably covers 99% of the workflow
- Launcher actions from any result (Claude, terminal, IDE, file manager, browser)

## Question

Is there an existing TUI / GUI / CLI tool that is actually a **GitHub repo fleet manager** in this sense? Not a Git client (single-repo), not a PR dashboard — a tool for managing the *set* of repos you own and their local clone state, with search and bulk ops. Please look hard — I suspect I've been missing something.
