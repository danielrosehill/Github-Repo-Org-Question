# Search-First Launcher — Design

Date: 2026-04-09
Prompt: `prompts/run/subsequent/2026-04-09-search-first-launcher.md`
Builds on: `outputs/individual/2026-04-09-autosymlink-existing-tools.md`

## Key Findings

This is the right reframe. **Stop trying to make the filesystem the index.** Let Claude reorganise folders freely — the launcher doesn't care because repo identity is `git remote get-url origin`, not a path. Bookmarks become obsolete.

The workflow collapses to three layers:

1. **An index** of every repo you care about (cloned or not), keyed by remote URL, with name + description + topics + GitHub Project membership.
2. **A launcher** with fuzzy search over the index.
3. **Action hotkeys** on each result for Claude / Konsole / VS Code / Dolphin / browser / combos.

## Launcher choice

Ranked for this use case on KDE Plasma 6:

| Launcher | Pro | Con | Verdict |
|---|---|---|---|
| **[Albert](https://albertlauncher.github.io/)** | Mature Python extension API, per-result **actions** are a first-class concept (Enter + Alt+1/2/3 etc.), cross-DE, actively maintained | Not KDE-native; one more background process | **Top pick** — actions model fits exactly |
| **[Ulauncher](https://ulauncher.io/)** | Very easy Python extensions, nice UI | Actions per result are clunkier than Albert; GTK-leaning | Strong runner-up |
| **KRunner** | Native Plasma 6, type-anywhere via default shortcut | Per-result alt-key actions are awkward; Python D-Bus runner template shaky (flagged in prior output) | Use later as a secondary entry point, not primary |
| **Rofi + script** | Ultra-lightweight, scriptable; `-kb-custom-N` gives per-key actions | Bespoke, you maintain the rendering | Good minimalist option |
| **fzf TUI bound to global shortcut** | Trivial to build, `--expect` gives you per-key actions out of the box | Terminal popup feels less polished | **Best MVP** — 20 lines of shell |

**Recommendation:** start with the fzf TUI (same-day MVP), migrate to Albert once you want a prettier always-available bar.

## The index

One SQLite file, three sources merged:

1. **`gh repo list <you> --limit 1000 --json nameWithOwner,description,repositoryTopics,url,sshUrl`** — every GitHub repo you own, cloned or not.
2. **`gh project list` + `gh project item-list`** — membership in each Project, joined on repo URL. This gives you topical grouping **without maintaining anything locally** — you already curate Projects, so reuse that curation. Refresh on a cron (hourly is fine).
3. **Local clone locations** — `fd -t d -H '\.git$' ~/repos` once, then `systemd.path` updates. Matched to index rows by `git remote get-url origin`. If a repo is in the index but not cloned, the launcher offers "Clone into `~/repos/github/_inbox/`" as an action.

Columns: `remote_url PK, name, owner, description, topics, projects, local_path NULLABLE, last_opened, open_count`.

Sort results by `open_count DESC` so your 10 daily repos float to the top — solves the "same 10 repos 99% of the time" case without manual pinning.

## Actions (hotkey bindings on a selected result)

| Key | Action | Command |
|---|---|---|
| `Enter` | Open in Claude Code | `konsole --workdir <path> -e bash -c 'claude; exec bash'` |
| `Alt+T` | Terminal only | `konsole --workdir <path>` |
| `Alt+C` | Claude + terminal side-by-side | `konsole --workdir <path> --new-tab -e claude` then another tab |
| `Alt+V` | VS Code | `code <path>` |
| `Alt+I` | JetBrains (IDEA/PyCharm) | `idea <path>` / `pycharm <path>` |
| `Alt+F` | Dolphin | `dolphin <path>` |
| `Alt+G` | GitHub page in browser | `xdg-open <repo_url>` |
| `Alt+K` | GitKraken | `gitkraken --path <path>` |
| `Alt+N` | Clone into `_inbox/` (if uncloned) | `gh repo clone <nwo> ~/repos/github/_inbox/<name>` |

Every action bumps `open_count` and `last_opened`.

## Minimum viable stack (fzf version — ship today)

```bash
# ~/.local/bin/repo-launch
#!/usr/bin/env bash
set -e
DB=~/.local/share/repo-index.db
choice=$(sqlite3 -separator $'\t' "$DB" \
  "SELECT name, description, local_path, remote_url
   FROM repos ORDER BY open_count DESC, name" \
  | fzf --delimiter=$'\t' \
        --with-nth=1,2 \
        --expect='alt-t,alt-v,alt-f,alt-g,alt-c,alt-n' \
        --preview='echo {} | cut -f2')

key=$(head -1 <<<"$choice")
row=$(tail -1 <<<"$choice")
path=$(cut -f3 <<<"$row")
url=$(cut -f4 <<<"$row")

case "$key" in
  alt-t) konsole --workdir "$path" ;;
  alt-v) code "$path" ;;
  alt-f) dolphin "$path" ;;
  alt-g) xdg-open "$url" ;;
  alt-c) konsole --workdir "$path" --new-tab -e claude ;;
  alt-n) gh repo clone "${url#*github.com/}" ~/repos/github/_inbox/ ;;
  *)     konsole --workdir "$path" -e bash -c 'claude; exec bash' ;;
esac

sqlite3 "$DB" "UPDATE repos SET open_count = open_count + 1,
  last_opened = datetime('now') WHERE remote_url = '$url'"
```

Bind to `Meta+R` in KWin → System Settings → Shortcuts → Custom Shortcuts. Done.

Separately:

- **`repo-index-sync`** — cron every hour: `gh repo list` + `gh project item-list` → upsert SQLite. ~50 lines of Python.
- **`repo-index-watch`** — `systemd.path` on `~/repos/github/` runs a tiny script that updates `local_path` for any new `.git/` by reading its remote.

## Albert v2 (when you want the nicer UX)

- Write a small Python extension reading the same SQLite DB.
- Each query returns an Albert `Item` with an `actions=[...]` list — Albert renders Enter + Shift+Enter + Ctrl+Enter as primary/secondary/tertiary natively. For more than three, use prefix queries (`r claude` → Claude, `rt claude` → terminal).
- Keeps the same DB, same sync scripts — only the front end changes.

## Why this is sustainable

- **Filesystem chaos is fine.** Claude can shuffle folders daily; the reconciler re-matches by remote URL. No bookmarks to break.
- **GitHub Projects is the organisation layer.** You already curate it. No second system to maintain.
- **Frecency solves the 10/hundreds split** without manual pinning.
- **Uncloned repos are first-class.** Search finds them; a hotkey clones them. The launcher is a unified view of "all repos I might touch", not "repos currently on disk".
- **Every piece is replaceable.** fzf → Albert → KRunner migrations don't require rebuilding the index.

## Open Questions

- Should the SQLite DB also sync across machines (Syncthing on `~/.local/share/repo-index.db`)? Open-count telemetry would then follow you.
- Worth indexing README head text for semantic search too, or is fuzzy-on-name+description+topics enough?
- GitHub Projects (v2) has a GraphQL-only API for some fields — does `gh project item-list` expose enough, or do we need a `gh api graphql` call?

## Sources

- [Albert launcher](https://albertlauncher.github.io/) · [Albert Python extension docs](https://albertlauncher.github.io/reference/python/)
- [Ulauncher](https://ulauncher.io/)
- [fzf `--expect` key bindings](https://github.com/junegunn/fzf#key-bindings-for-command-line)
- [gh repo list](https://cli.github.com/manual/gh_repo_list) · [gh project](https://cli.github.com/manual/gh_project)
- [systemd.path](https://www.freedesktop.org/software/systemd/man/systemd.path.html)
- [KWin custom shortcuts](https://userbase.kde.org/Plasma/Shortcuts)
