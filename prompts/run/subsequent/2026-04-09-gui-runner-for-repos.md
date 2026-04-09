# Prompt — GUI runner for repos (complementary to other tooling)

Date: 2026-04-09
Builds on: `outputs/individual/2026-04-09-search-first-launcher.md`, `outputs/individual/2026-04-09-multi-machine-sync.md`

## Context

Complementary to the other tooling. I want a **GUI runner** specifically — like KRunner / Spotlight / Alfred / Raycast — but scoped to repos.

## Desired behaviour

- Invoke by terminal command **or** global hotkey.
- Knows `~/repos/github/` is the base path.
- I type a repo name → fuzzy matches.
- Biased towards most-commonly-opened repos (MRU / frecency).
- Enter → default open action.
- Hotkeys on a result for: open in Claude Code, open in terminal, both, open in file manager.

## Question

Does a turnkey tool exist? If not, spec out the minimum to build it (it may overlap with the earlier launcher spec — focus on the GUI-runner-specific angle here: which host launcher, what's the shortest path to working).
