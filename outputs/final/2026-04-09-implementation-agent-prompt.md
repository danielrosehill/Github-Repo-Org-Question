# Implementation Agent Prompt — GitHub Repo Fleet Management

Date: 2026-04-09
Companion to: `outputs/final/2026-04-09-repo-management-synthesis.md`
Purpose: Self-contained brief for another AI agent tasked with implementing, installing, and validating the stack designed in the synthesis document.

---

## Copy everything below this line into the downstream agent ———————————

You are implementing a personal GitHub repo fleet management stack for Daniel Rosehill on his Ubuntu 25.10 / KDE Plasma 6 desktop (and eventually his laptop). Prior research has already settled the architecture — **your job is implementation, installation, and validation, not redesign**. Only deviate from the architecture if you hit a concrete blocker, and surface the deviation explicitly before acting.

### Background you need to internalise before touching anything

Daniel has hundreds of personal GitHub repos cloned under `~/repos/github/`. The pain: navigation is slow, bookmarks break whenever folders are reorganised, laptop clones drift behind desktop, and bulk lifecycle ops have no good home. The root insight from research: **`git remote get-url origin` is the only stable identity for a repo** — never a filesystem path. Every component below keys on remote URL so that the filesystem layout becomes irrelevant and Claude can reorganise folders freely without breaking anything downstream.

The architecture has five layers, each independently replaceable:

1. **Identity:** `remote_url` as primary key everywhere.
2. **Index:** single SQLite DB at `~/.local/share/repo-index.db`.
3. **GUI runner:** Rofi now, Albert later. Hotkey `Meta+R`. Per-result action hotkeys for Claude / terminal / VS Code / Dolphin / GitHub page / clone.
4. **Clone-set sync across machines:** [git-repo-manager (GRM)](https://github.com/hakoerber/git-repo-manager), manifest lives in its own git repo.
5. **Lifecycle ops:** reachable from the runner, plus weekly cron regenerating the manifest.

**Load full context before starting.** Read these files in order — they contain the complete reasoning and every rejected alternative, so you understand not just *what* but *why*:

- `outputs/final/2026-04-09-repo-management-synthesis.md` — the architecture
- `outputs/individual/2026-04-09-search-first-launcher.md` — runner design
- `outputs/individual/2026-04-09-gui-runner-for-repos.md` — working Rofi + Albert code
- `outputs/individual/2026-04-09-multi-machine-sync.md` — GRM setup
- `outputs/individual/2026-04-09-fleet-manager-tools.md` — ecosystem survey (what NOT to reach for)
- `outputs/individual/2026-04-09-db-backed-repo-manager.md` — index design
- `outputs/individual/2026-04-09-repo-org-and-portability.md` — original framing

### Non-negotiable constraints

1. **Data-loss protection is hard.** Never bulk-force-pull, never auto-prune local clones, never run any `git` command that can discard uncommitted changes or unpushed commits without explicit Daniel confirmation. GRM already enforces this — do not add `--force` flags to work around its refusals.
2. **No destructive remote ops in automation.** No `gh repo delete`, no bulk remote ops in any cron or script. Destructive remote work stays manual (reporemover.xyz or interactive `gh`).
3. **Remote URL is the primary key.** Do not use paths as identity anywhere. Normalise URLs (strip trailing `.git`, lowercase host) before hashing/comparing.
4. **No scope creep.** Do not add semantic search over README contents in v1 — fuzzy on name/description/topics/projects is the target. Do not add KRunner integration yet. Do not mass-index uncloned repos in v1 (add in v2).
5. **Keep the glue small.** Every piece should be replaceable. Prefer ~50 LOC shell/Python over a framework.
6. **Read before writing.** Use `Read` on existing files before editing; never assume structure.
7. **Test on the desktop first.** Laptop comes later.

### Implementation plan — execute in order

#### Phase 1: The index and population script (~1 hour)

1. Create `~/.local/share/repo-index.db` with this schema:
   ```sql
   CREATE TABLE IF NOT EXISTS repos (
     remote_url  TEXT PRIMARY KEY,
     name        TEXT NOT NULL,
     owner       TEXT,
     description TEXT,
     topics      TEXT,             -- JSON array
     projects    TEXT,             -- JSON array, nullable
     local_path  TEXT,             -- NULL if uncloned
     open_count  INTEGER DEFAULT 0,
     last_opened TEXT,
     dirty       INTEGER DEFAULT 0
   );
   CREATE INDEX IF NOT EXISTS idx_name ON repos(name);
   CREATE INDEX IF NOT EXISTS idx_frecency ON repos(open_count DESC, last_opened DESC);
   ```
2. Write `~/.local/bin/repo-index-sync` in Python (~100 LOC):
   - `gh repo list danielrosehill --limit 1000 --json nameWithOwner,description,repositoryTopics,url,sshUrl` → upsert metadata keyed on normalised `url`.
   - Walk `~/repos/` with `fd -t d -H '^\.git$'`, read each parent's `git remote get-url origin`, normalise, match to existing rows, fill `local_path`. Clear `local_path` on rows whose previously stored path no longer exists on disk.
   - For each `local_path`, run `git -C <path> status --porcelain` and set `dirty` to 1 if any output.
   - Skip GitHub Projects in phase 1 — add in phase 4.
3. Run it manually once. Verify row count roughly matches `gh repo list --limit 1000 | wc -l`. Spot-check three cloned repos have correct `local_path`.
4. Install as a systemd user timer running hourly:
   - `~/.config/systemd/user/repo-index-sync.service`
   - `~/.config/systemd/user/repo-index-sync.timer`
   - `systemctl --user daemon-reload && systemctl --user enable --now repo-index-sync.timer`

**Validation:** `sqlite3 ~/.local/share/repo-index.db "SELECT COUNT(*) FROM repos; SELECT COUNT(*) FROM repos WHERE local_path IS NOT NULL; SELECT COUNT(*) FROM repos WHERE dirty = 1;"` — numbers should be plausible.

#### Phase 2: The Rofi runner (~30 minutes)

1. Check whether Daniel's session is Wayland (`echo $XDG_SESSION_TYPE`). If Wayland, install `rofi-wayland` instead of `rofi`. Confirm it launches (`rofi -show drun` test).
2. Create `~/.local/bin/repo-runner` — use the script from `outputs/individual/2026-04-09-gui-runner-for-repos.md` as the starting point. Preserve its keybindings exactly: `Alt+T` terminal, `Alt+V` VS Code, `Alt+F` Dolphin, `Alt+C` Claude+terminal, `Alt+G` browser, `Enter` = Claude in Konsole. Ensure every action path bumps `open_count` and sets `last_opened = datetime('now')` for the selected `remote_url`.
3. Handle edge cases:
   - Empty DB → show "no repos indexed yet, run repo-index-sync".
   - Selected repo has `local_path IS NULL` → only allow `Alt+G` (open GitHub page) and `Alt+N` (clone into `~/repos/github/_inbox/` then open in Claude).
   - Uncommitted changes (`dirty = 1`) → show a `[dirty]` tag in the Rofi row so Daniel sees it before opening.
4. Bind `Meta+R` to `~/.local/bin/repo-runner` via KDE System Settings → Shortcuts → Custom Shortcuts. Test the binding works system-wide.

**Validation:** press `Meta+R`, type "claude", confirm fuzzy match, press Enter, confirm Konsole opens at the repo with `claude` running. Close it, press `Meta+R` again, confirm that repo now floats higher in the list.

#### Phase 3: GRM clone-set sync (~1 hour)

1. Install GRM: `cargo install git-repo-manager` or download a release binary from https://github.com/hakoerber/git-repo-manager/releases.
2. Generate initial manifest:
   ```
   mkdir -p ~/repos-manifest
   cd ~/repos-manifest
   grm repos find config github --token "$(gh auth token)" --owner danielrosehill > config.toml
   ```
   Review the file. Confirm paths point under `~/repos/github/<name>` (flat, no topical subdirs — the runner handles grouping, not the filesystem).
3. `git init` in `~/repos-manifest`, create private GitHub repo `daniel-repos-manifest` (`gh repo create --private`), commit `config.toml`, push.
4. Write `~/.local/bin/repos-manifest-regen` that re-runs the `grm repos find` command, diffs against the committed `config.toml`, and if changed: commits with message `chore: refresh manifest YYYY-MM-DD` and pushes. Install as a weekly systemd user timer.
5. Write the laptop alias for `~/.bashrc` (but don't install on laptop yet — phase 6):
   ```bash
   repos-sync() {
     cd ~/repos-manifest || return
     git pull --ff-only || { echo "manifest pull failed"; return 1; }
     grm repos status config.toml
     read -p "Proceed with sync? [y/N] " ans
     [[ "$ans" == "y" ]] || return
     grm repos sync config.toml
   }
   ```

**Validation:** on the desktop, run `grm repos status config.toml` — it should report all repos as clean / already-cloned / no action needed. Intentionally make a tiny uncommitted change in one repo, re-run status, confirm GRM flags it.

#### Phase 4: GitHub Projects grouping (~30 min)

Extend `repo-index-sync` to also call:
- `gh project list --owner danielrosehill --format json` → list of projects
- For each, `gh project item-list <number> --owner danielrosehill --format json` → repo memberships
- Populate `repos.projects` as JSON array of project titles

Verify a repo known to be in a GitHub Project now has that project in its `projects` column. Update the Rofi script to include project names in the fuzzy search corpus (concatenate name + description + projects into the display string or a hidden match field).

#### Phase 5: Inbox convention (~5 min)

1. `mkdir -p ~/repos/github/_inbox`
2. Open GitKraken → Preferences → set default clone path to `~/repos/github/_inbox/`.
3. Confirm the `systemd.path` watcher from the index script picks up new clones there within a minute (test by `gh repo clone` into `_inbox`).

(If no `systemd.path` watcher was added, the hourly timer is enough for v1.)

#### Phase 6: Laptop (only after desktop is stable for a week)

1. Install GRM on the laptop.
2. Clone `daniel-repos-manifest`.
3. Add the `repos-sync` alias.
4. Run `repos-sync`. GRM should clone everything missing and skip anything dirty. Confirm zero data loss.
5. Install the index sync + Rofi runner too. Optionally sync `~/.local/share/repo-index.db` via Syncthing so frecency follows Daniel across machines.

### Testing checklist

Run through these before declaring done:

- [ ] `repo-index-sync` runs clean, hourly timer active, row counts plausible.
- [ ] `Meta+R` opens Rofi with repos, most-used ones on top.
- [ ] Each hotkey (`Enter`, `Alt+T/V/F/C/G/N`) launches the correct action.
- [ ] `open_count` increments after each action.
- [ ] A dirty repo shows `[dirty]` in the list.
- [ ] An uncloned repo (in `gh repo list` but not locally) appears in Rofi and `Alt+N` clones it into `_inbox/`.
- [ ] GRM refuses to sync a repo you intentionally dirtied.
- [ ] Manifest regen cron commits and pushes a diff when you create a new GitHub repo.
- [ ] Moving a repo's folder on disk and re-running `repo-index-sync` updates `local_path` without creating a duplicate row. **This is the central correctness test — verify explicitly.**
- [ ] GitHub Projects membership appears in the index after phase 4.

### When to ask Daniel vs. proceed autonomously

- **Proceed:** installing packages, creating scripts, setting up systemd user units, writing the Rofi script, creating local dirs, `gh repo create --private` for the manifest repo.
- **Ask first:** anything that touches more than one repo destructively, any `rm -rf` outside `_inbox`, any GRM sync with `--force`, any change to GitKraken config beyond the default clone path, installing cargo toolchain if not present.
- **Surface and stop:** if any validation step fails in a way you don't understand — especially the "moving a folder updates `local_path`" test. That test failing means the identity model is broken and the whole stack rests on it.

### Out of scope (do not implement in this pass)

- Albert extension (revisit after Rofi is a daily driver for a week).
- KRunner runner.
- Semantic embedding search.
- Multi-provider support (GitLab, Gitea, etc.).
- Tag editing UI (tags come from GitHub Projects, not local state).
- Syncthing setup for the DB (optional, phase 6+).

### Reporting back

When done, produce a short report:
- What you built vs. what the plan said.
- Any deviations and why.
- Validation results against the checklist above.
- Known issues and follow-ups.
- Exact commands to invoke each piece (runner, manual sync, manifest regen).

Do not summarise the architecture back at Daniel — he wrote it. Report only on implementation facts.
