# SCOPE — GitHub Repo Fleet Management

Living spec for this research notebook. Updated as new pain points surface and as research rules options in or out. Read this before resuming work.

Last updated: 09/04/26

## The question

How does a single heavy user manage hundreds of personal GitHub repos across multiple machines without wasting time on navigation, losing work to sync accidents, or fighting the filesystem every time folders get reorganised?

## User context

- **Volume:** hundreds of personal repos under `~/repos/github/`, growing continuously
- **Machines:** desktop (80% of work) + laptop (20%, occasional)
- **Default clone tool:** GitKraken, clones into `~/repos/github/` by default
- **File manager:** Dolphin on KDE Plasma 6 (Wayland)
- **Primary editors:** Claude Code (in Konsole), VS Code, occasionally JetBrains
- **Existing curation:** GitHub Projects are actively maintained and represent Daniel's real mental grouping of repos
- **Usage pattern:** ~10 repos account for 99% of daily use; hundreds more are periodic

## Pain points (empirical, accumulated across iterations)

1. **Flat dumps become unmanageable.** A single folder of hundreds of repos is unnavigable.
2. **Topical subfolders break bookmarks.** Every time Claude (or Daniel) reorganises `~/repos/github/` into categories, every Dolphin bookmark pointing at a repo breaks. Rebookmarking is not sustainable at this volume.
3. **Organisation structure is not version-controlled.** Whatever layout exists on the desktop does not replicate to the laptop.
4. **Navigation is the biggest daily time-sink.** Finding a repo — even one of the 10 daily ones — takes too long.
5. **Common actions are unshortcutted.** Open in Claude Code, open terminal at path, open both, open in file manager, open in IDE, open GitHub page — all repetitive, none hotkeyed.
6. **Laptop clones drift badly.** After a few weeks away, the laptop's repo set is stale. Cloning or updating one by one is impractical.
7. **No good home for bulk lifecycle ops.** Deleting a local clone, deleting a remote repo, pruning orphans, cloning missing repos, bulk `git pull` — scattered across ad-hoc commands.
8. **Data-loss risk is unacceptable.** Any bulk operation must never silently discard uncommitted changes, unpushed commits, or untracked files.
9. **Favourites/pins are unstable.** Any manual "top 10" list is obsolete within weeks as priorities shift — favourites need to be frecency-driven, not curated.
10. **Reorganisation is a first-class event.** Claude is expected to reorder folders as a normal operation; any design that treats filesystem layout as stable is broken by default.

## Hard requirements

- **Identity must not be a filesystem path.** `git remote get-url origin` is the only stable key.
- **Frecency-driven ordering.** No manual favourites curation.
- **Data-loss protection** on any bulk sync / pull / delete operation. Refuse-on-dirty is the default.
- **Multi-machine replicable.** Whatever organisation layer exists must travel via a git-committable artefact.
- **Filesystem layout is free to change** without breaking anything downstream.
- **GUI + CLI access.** A global hotkey launcher for the common case, a CLI for scripting and automation.

## Desired capabilities

### Inventory & state
- List every GitHub repo owned (cloned or not)
- Reconcile against local clones by remote URL
- Surface: uncloned remote repos, orphaned local clones, stale clones, dirty clones
- Membership in GitHub Projects available as grouping metadata

### Navigation
- Fuzzy search by repo name / description / topics / project membership
- Frecency bias toward most-used repos
- Global hotkey (`Meta+R` or similar) to invoke
- Per-result action hotkeys:
  - `Enter` → open in Claude Code
  - `Alt+T` → terminal at path
  - `Alt+C` → Claude + terminal
  - `Alt+V` → VS Code
  - `Alt+F` → Dolphin
  - `Alt+G` → GitHub page in browser
  - `Alt+N` → clone into `_inbox/` (for uncloned repos)

### Sync & lifecycle
- Bulk clone missing repos on a fresh or stale machine
- Bulk `git pull` across all clones (safe — refuse on dirty)
- Version-controlled manifest of "which repos should exist locally"
- Delete local / delete remote / delete both — available but gated behind confirmation
- Weekly auto-regeneration of the manifest from the live GitHub account

## Settled architecture (as of 09/04/26)

Five layers, all keyed on remote URL. See `outputs/final/2026-04-09-repo-management-synthesis.md` for full rationale.

1. **Identity:** normalised `remote_url` as primary key.
2. **Index:** `~/.local/share/repo-index.db` (SQLite), populated from `gh repo list` + `gh project item-list` + `fd` walk, on an hourly timer plus a `systemd.path` watcher.
3. **GUI runner:** Rofi MVP (week 1), Albert extension later. Bound to `Meta+R`, reads the same DB.
4. **Clone-set sync:** `git-repo-manager` (GRM) with a TOML manifest stored in a private `daniel-repos-manifest` repo. Weekly regen cron on desktop; `repos-sync` alias on laptop.
5. **Grouping:** GitHub Projects joined into the index — no local taxonomy to maintain.

## Tools evaluated

### Recommended for use
- **git-repo-manager (GRM)** — clone-set sync across machines; the only tool with built-in uncommitted-change safety. **Non-negotiable dependency.**
- **Rofi** (`rofi-wayland` on Plasma 6 Wayland) — MVP GUI runner host; per-result `Alt+N` hotkeys via `-kb-custom-N`.
- **Albert launcher** — polished v2 runner host; per-result actions are first-class in its API.
- **GitHub CLI (`gh`)** — inventory, project membership, destructive ops (manual).

### Worth knowing, not primary
- **ogit** — closest turnkey fleet-inventory TUI; missing bulk delete and state views
- **gh-gr** — gh extension for bulk pull/push; no TUI or delete
- **gh-repo-man** — fzf-powered interactive clone with filters; remote-only
- **repo-hub / repolice** — Rust TUI for dirty-state scanning across clones
- **Repo Remover (reporemover.xyz)** — web app for bulk remote delete/archive; use for occasional sweeps
- **sesh** — tmux session manager with zoxide frecency; 90% of navigation if you lived in tmux
- **zoxide** — complementary CLI frecency jumper

### Ruled out
- **ghq** — canonical `host/user/repo` path fights topical grouping
- **ghorg** — mass clone/sync but no dirty-worktree safety
- **mani / gita / myrepos** — config-file based, no auto-detect, no GitHub discovery
- **Symlink farms (GNU Stow + systemd.path + reconcile)** — the wrong primitive; replaced by the search-first launcher
- **KRunner as primary runner** — per-result Alt-key actions awkward; Plasma 6 Python runner template still shaky
- **Sourcegraph self-hosted** — overkill
- **Semantic search over README contents** — premature; fuzzy-on-metadata covers 99%
- **Manual favourites pinning** — replaced by frecency

## Open questions

- Should `~/.local/share/repo-index.db` sync via Syncthing so frecency follows across machines?
- Should the manifest-regen cron also auto-flag stale repos (no commits in N months) for review?
- Is there value in per-machine manifest overrides (e.g. exclude huge model/dataset repos from laptop)?
- Is this gap (~500 LOC glue over GRM + Rofi/Albert + SQLite + GitHub Projects) worth publishing as an OSS project?

## How to evaluate a new tool against this spec

When a new candidate surfaces, run `/resume evaluate <tool>` or score it manually against:

1. **Identity model** — does it key on remote URL or on path?
2. **Data-loss safety** — refuse-on-dirty by default?
3. **Inventory scope** — does it know about uncloned repos too, or only local ones?
4. **Navigation** — fuzzy + frecency + per-result action hotkeys?
5. **Multi-machine** — git-committable manifest or config?
6. **Bulk ops** — which of the capability list does it cover?
7. **Composability** — does it play nicely with the existing five-layer stack, or does it want to own everything?

A tool that loses on (1) or (2) is disqualified regardless of other features.
