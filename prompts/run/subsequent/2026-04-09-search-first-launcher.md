# Prompt — Search-first launcher with action hotkeys

Date: 2026-04-09
Builds on: `outputs/individual/2026-04-09-autosymlink-existing-tools.md`

## Context & reframing

Stepping back from filesystem-based organisation entirely. The real pain point is **navigation**, not storage. Bookmarks break every time Claude reorganises folders — not sustainable.

## Workflow to support

- Common case: I need the same ~10 repos 99% of the time; the other hundreds are periodic.
- I often start by searching for a repo by fuzzy name (e.g. "My Weird Prompts podcast").
- Once I've found it, I want a **hotkey** to perform one of:
  - Open in Claude Code (spawn Konsole + `claude` at path)
  - Open terminal at path (Konsole, no Claude)
  - Open in a full IDE (VS Code / JetBrains)
  - Open in file manager (Dolphin)
  - Spawn Claude *and* open a terminal
  - Open the GitHub repo page in a browser
- **GitHub Projects** integration matters — Projects give me useful grouping "for free" and I already maintain them.

## Question

Design a search-first launcher system that makes the filesystem layout irrelevant. What existing launcher (KRunner, Albert, Ulauncher, Rofi, fzf TUI, …) is the best host? How should GitHub Projects be pulled in? What's the minimum viable stack?
