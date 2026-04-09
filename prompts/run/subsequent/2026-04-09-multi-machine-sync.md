# Prompt — Multi-machine clone-set sync with data-loss protection

Date: 2026-04-09
Builds on: `outputs/individual/2026-04-09-fleet-manager-tools.md`

## Context

80% of work happens on the desktop, 20% on the laptop. When I open the laptop occasionally, its GitHub repos are badly out of date. Cloning or reorganising them one by one is not practical.

## What I want

- A **version-controlled "tree"** describing the set of repos I currently clone, shared across machines.
- On a new or stale machine, run one command that reconciles the local clone set to match the tree: clone what's missing, prune what's been removed, update everything else.
- **Bulk pull / push** across all clones.
- **Data-loss protection**: must never silently drop uncommitted changes, unpushed commits, or untracked files. If anything is at risk, the tool should refuse or prompt, not barrel through.

## Question

What's the right design? What existing tools cover this — is there anything purpose-built, or is this another compose-your-own situation? How should the "tree" be represented, and what's the safe reconcile algorithm?
