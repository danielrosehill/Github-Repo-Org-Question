# Managing a Large Personal GitHub Repo Fleet — Synthesis & Recommendation

Date: 2026-04-09
Status: Final summary of today's research iteration
Inputs:
- `outputs/individual/2026-04-09-repo-org-and-portability.md`
- `outputs/individual/2026-04-09-db-backed-repo-manager.md`
- `outputs/individual/2026-04-09-autosymlink-existing-tools.md`
- `outputs/individual/2026-04-09-search-first-launcher.md`
- `outputs/individual/2026-04-09-fleet-manager-tools.md`
- `outputs/individual/2026-04-09-multi-machine-sync.md`
- `outputs/individual/2026-04-09-gui-runner-for-repos.md`

## The problem, restated

Daniel manages hundreds of personal GitHub repos, mostly under `~/repos/github/`. Pain points accumulated over the day:

1. The flat dump becomes unmanageable; topical subfolders help but **break Dolphin bookmarks** every time they're reorganised.
2. The organisation structure itself is not version-controlled — it can't easily be replicated on another machine.
3. Navigation wastes time: the same ~10 repos are used 99% of the time, but finding them is slow.
4. Common actions (open in Claude Code, terminal, IDE, file manager) are repetitive and unshortcutted.
5. Laptop clones drift badly behind desktop because one-by-one cloning is impractical.
6. Bulk lifecycle ops (delete local, delete remote, prune orphans, clone missing) have no good home.
7. Data-loss protection is non-negotiable for any bulk sync.

## The key insight that resolved the whole thing

**Stop treating the filesystem as the index.** Every approach that keyed organisation on paths — symlink farms, bookmarks, topical subfolders — was fighting the fact that paths are unstable. The moment you accept that **`git remote get-url origin` is the only stable identity**, every downstream problem simplifies:

- Claude can reorganise `~/repos/github/` freely; nothing downstream breaks.
- Dolphin bookmarks become obsolete — replaced by a search-first launcher.
- Multi-machine sync becomes a manifest reconcile, not a path-tree copy.
- Grouping moves out of the filesystem entirely — into **GitHub Projects**, which Daniel already curates.
- Frecency (`open_count` per repo) solves the "10 daily + hundreds periodic" split without manual pinning.

One index keyed on remote URL. Multiple front ends and sync tools reading it. That is the architecture.

## Research summary — what the iterations established

| # | Question | Conclusion |
|---|---|---|
| 1 | Fluid ways to organise repos + version-control structure? | Manifest-driven layout + symlink farm is possible but brittle; points toward a DB approach. |
| 2 | DB-backed repo manager with semantic search? | No turnkey tool. Stack: SQLite + sqlite-vec + `watchdog` + `fastembed` + Textual TUI. Identity = remote URL hash. |
| 3 | Existing auto-symlink tool that survives moves? | No. Closest: `systemd.path` + GNU Stow + reconcile script. Symlinks are the wrong primitive — reframed the problem. |
| 4 | Search-first launcher with action hotkeys? | Right reframe. Layer 1 SQLite index (gh repo list + gh project + watched dir), layer 2 launcher (fzf → Albert → KRunner), layer 3 per-result action hotkeys. GitHub Projects supplies grouping for free. |
| 5 | Existing "GitHub fleet manager" tools? | No single tool. Closest: `ogit` + `gh-gr` + `repo-hub` + `reporemover.xyz`. Real ~500 LOC gap in the ecosystem. |
| 6 | Multi-machine clone-set sync with data-loss protection? | **git-repo-manager (GRM)** is purpose-built and is the only tool with built-in uncommitted-change safety. Manifest auto-generated from `gh`, committed to a private repo, synced across machines. |
| 7 | GUI runner for repos? | No turnkey tool but 15-minute Rofi+SQLite script hits it; Albert extension is the polished version. Same SQLite index as everything else. |

## The recommended architecture

Five layers, all keyed on remote URL, each independently replaceable.

```
┌─────────────────────────────────────────────────────────────┐
│  GUI RUNNER          Rofi (today) → Albert (v2)             │  ← Meta+R hotkey
│   ↓ reads                                                    │
│  INDEX               ~/.local/share/repo-index.db (SQLite)  │
│   ↑ populated by                                             │
│  SOURCES  ┌─ gh repo list       (remote inventory)          │
│           ├─ gh project item-list (topical grouping)        │
│           └─ fd + systemd.path   (local clone discovery)    │
│                                                              │
│  CLONE-SET SYNC      git-repo-manager (GRM)                 │  ← across machines
│   ↑ driven by                                                │
│  MANIFEST            ~/repos-manifest/config.toml           │
│   ↑ regenerated from gh repo list, committed, pushed        │
└─────────────────────────────────────────────────────────────┘
```

### Layer 1 — Identity

`remote_url` is the primary key everywhere. Never a filesystem path. This is the load-bearing decision.

### Layer 2 — The index (`~/.local/share/repo-index.db`)

```sql
CREATE TABLE repos (
  remote_url  TEXT PRIMARY KEY,
  name        TEXT NOT NULL,
  owner       TEXT,
  description TEXT,
  topics      TEXT,             -- JSON array
  projects    TEXT,             -- JSON array (GitHub Projects membership)
  local_path  TEXT,             -- NULL if uncloned
  open_count  INTEGER DEFAULT 0,
  last_opened TEXT,
  dirty       INTEGER DEFAULT 0 -- cached `git status --porcelain` nonempty
);
```

Populated by one ~80-line Python script on an hourly cron:

1. `gh repo list danielrosehill --limit 1000 --json ...` → upsert metadata.
2. `gh project list` + `gh project item-list` → join on repo URL, fill `projects`.
3. `fd -t d -H '^\.git$' ~/repos/` then `git -C <parent> remote get-url origin` → fill `local_path` by matching remote URL. Survives moves automatically.
4. For each `local_path`, cache `git status --porcelain` into `dirty`.

Plus a **`systemd.path` watcher** on `~/repos/github/` for near-real-time updates when new clones appear.

### Layer 3 — The GUI runner

- **Week 1:** Rofi + 50-line shell script bound to `Meta+R`. Fuzzy match on `name`, order by `open_count DESC`, per-result hotkeys:
  - `Enter` → Claude Code in Konsole
  - `Alt+T` → terminal only
  - `Alt+C` → Claude + terminal side-by-side
  - `Alt+V` → VS Code
  - `Alt+F` → Dolphin
  - `Alt+G` → GitHub page in browser
  - `Alt+N` → clone uncloned repo into `~/repos/github/_inbox/`
  - Every action bumps `open_count` and `last_opened`
- **Later:** port to Albert Python extension when Rofi feels limiting. Same DB, better action UX.

### Layer 4 — Clone-set sync across machines (GRM)

- `~/repos-manifest/` is a private GitHub repo containing `config.toml`.
- **Desktop weekly cron** regenerates `config.toml` from `gh`, commits diffs, pushes.
- **Laptop alias** `repos-sync`: pulls the manifest, runs `grm repos status` (shows dirty repos), prompts, then `grm repos sync`. GRM refuses to touch dirty worktrees by default — data-loss protection satisfied.
- Manifest repo also stores exported favourites and frecency snapshot so MRU travels between machines. (Optional: Syncthing `~/.local/share/repo-index.db` directly.)

### Layer 5 — Bulk lifecycle ops

Mostly reachable from the runner via action hotkeys on selected results:

- **Delete local:** `Alt+D` → confirm → `rm -rf` + clear `local_path`.
- **Delete remote:** rare and destructive — keep out of the runner. Use [reporemover.xyz](https://reporemover.xyz) for occasional sweeps.
- **Clone missing:** `Alt+N` clones single repo into `_inbox/`. Bulk "clone everything I don't have locally" is what GRM sync already does.
- **Bulk pull:** `grm repos sync` (safe) or `gh-gr pull` (faster, less safe).
- **Bulk push:** deliberately not automated — footgun. Push per-repo from the runner.
- **Dirty view:** `dirty=1` filter in Rofi, or `repo-hub` as a dedicated TUI when needed.

## Top-level thoughts

1. **The ecosystem genuinely lacks this tool.** Today confirmed that no single product does what Daniel wants. The closest pieces — GRM for sync, ogit for inventory, Rofi/Albert for launching, GitHub Projects for grouping — compose well if you accept that the glue is yours. Given how many heavy GitHub users have this problem, the ~500 LOC combining them is a plausible open-source project worth publishing.
2. **GRM is the only non-negotiable third-party dependency.** Its uncommitted-change safety model is not reproducible in a weekend script, and the use case (multi-machine laptop drift) is the one with real data-loss risk. Everything else in the stack is replaceable shell and SQL.
3. **GitHub Projects is the under-used pillar.** It turns Daniel's existing curation into the grouping layer for free, which eliminates the entire "version-control the folder tree" sub-problem that started the conversation. The folder tree no longer needs to mean anything.
4. **Frecency beats manual favourites.** Every attempt to pin the daily 10 breaks as priorities shift. `ORDER BY open_count DESC` is self-maintaining and reflects real usage.
5. **Ship Rofi today, not Albert next month.** The 15-minute script is a daily driver that makes the pain stop now, and it uses the same DB the polished version will use — zero rework cost.
6. **The `_inbox/` convention matters.** Point GitKraken's default clone path at `~/repos/github/_inbox/` so new repos land somewhere the watcher can pick up and the user can triage. It also gives the runner a natural home for its "clone uncloned" action.

## Concrete next steps

1. **Today (15 min):** create empty `~/.local/share/repo-index.db`, write the Rofi script, bind `Meta+R`.
2. **Today (30 min):** write the hourly cron script (`gh repo list` + `fd` + match by remote URL). Populates the DB.
3. **This week:** install GRM, generate initial manifest, create `daniel-repos-manifest` private repo, add the weekly manifest-regen cron on the desktop.
4. **Next laptop session:** clone the manifest, add the `repos-sync` alias, run it — should reconcile the laptop's clone set in one command.
5. **Add GitHub Projects sync** (`gh project item-list`) to the hourly cron once steps 1–4 are working.
6. **Next weekend:** port the runner to Albert for the polished UX.
7. **Later:** consider publishing the glue as an OSS project — there's a real audience for it.

## What was deliberately not solved

- **Semantic search over README contents.** Interesting but premature — fuzzy search over name + description + topics + projects will cover 99% of lookups. Revisit only if that stops being enough.
- **KRunner integration.** Plasma 6 Python runner template is still shaky. Revisit in ~6 months.
- **Uncloned-but-searchable repos via `gh repo list`.** Worth adding in week 2, not week 1 — keeps the MVP scope tight.
- **Bulk destructive ops (mass delete remote).** Deliberately kept out of daily tooling. Use the web tool for sweeps, not automation.

## Sources

See individual outputs in `outputs/individual/` for full source lists. Primary tools referenced:

- [git-repo-manager (GRM)](https://github.com/hakoerber/git-repo-manager)
- [Rofi](https://github.com/davatorium/rofi) · [rofi-wayland](https://github.com/lbonn/rofi)
- [Albert launcher](https://albertlauncher.github.io/)
- [GitHub CLI](https://cli.github.com/) (`gh repo list`, `gh project item-list`)
- [ogit](https://github.com/wmalik/ogit)
- [gh-gr](https://github.com/sarumaj/gh-gr)
- [repo-hub](https://github.com/daffyzk/repo-hub)
- [systemd.path](https://www.freedesktop.org/software/systemd/man/systemd.path.html)
- [watchdog](https://github.com/gorakhargosh/watchdog)
- [fd](https://github.com/sharkdp/fd)
- [zoxide](https://github.com/ajeetdsouza/zoxide) (complementary, CLI side)
