# Existing Tools for Auto-Symlinking New Repos

Date: 2026-04-09
Prompt: `prompts/run/subsequent/2026-04-09-autosymlink-existing-tools.md`

## Key Findings

**Short answer: no single existing tool does all three things.** But you can compose 2–3 boring, well-maintained building blocks to get 90% there without writing an application.

The honest tension: *symlinks themselves don't survive moves* — if the target directory is moved, the symlink becomes a dangling link. Anything that "makes symlinks survive moves" is really something that **re-points the symlink after a move is detected**. So the realistic options split into two camps: (a) keep symlinks and add a reconciler, or (b) skip symlinks and use a tool that indexes by something more stable than path.

## Option A — Symlink farm + watcher (closest to what you asked for)

Three boring pieces:

1. **`systemd.path` unit** or **`inotifywait`** watches `~/repos/github/` for new directories. `systemd.path` is the more modern/robust choice — it triggers a `.service` when a path changes. No daemon you wrote yourself.
2. **GNU Stow** manages the symlink farm. You keep a "package" directory per category (`~/repos/_links/claude-code/`, `_links/clients/`, etc.) and Stow creates/removes symlinks cleanly. It's battle-tested (dotfile managers have used it for 20 years) and handles add/remove without leaving orphans.
3. **A ~30-line reconcile script** runs on the `systemd.path` trigger *and* on a timer. It:
   - detects new `.git/` dirs and prompts (or auto-files by rules) which category symlink farm to add them to,
   - walks existing symlinks, detects dangling ones, searches `~/repos/` for the moved target by remote URL (`git -C <dir> remote get-url origin`), and re-points the symlink.

This gives you:

- ✅ auto-symlink on birth (systemd.path)
- ✅ categorised symlink stores (Stow packages)
- ✅ folder symlinks survive moves (reconciler re-points by remote URL)
- ✅ bookmarkable in Dolphin (bookmark the Stow target dir, never the underlying repo)

It's not an "existing tool" in the single-install sense, but every piece is off-the-shelf and the glue is tiny. This is genuinely the pragmatic minimum.

## Option B — Skip symlinks entirely

If the goal is really just "find and jump to a repo fast without caring where it lives", symlinks may be the wrong primitive:

- **[zoxide](https://github.com/ajeetdsouza/zoxide)** — frecency-based directory jumper. Learns the dirs you actually use; `z claude` jumps to the most-used matching dir. Handles moves naturally (new location just replaces old in the index). Terminal/Claude-launch use case solved cleanly. **Does not help Dolphin bookmarks.**
- **[fzf](https://github.com/junegunn/fzf) + `fd`** — `fd -t d -H '\.git$' ~/repos | fzf` gives you a live fuzzy picker over every repo. Bind to a global shortcut via KWin + a small wrapper that opens Dolphin/Konsole/Claude at the choice. No symlinks, no reconciler, no DB.
- **KDE Plasma "Places"** — you can add categorised entries in the Places panel manually. Painful to maintain but zero tooling.

## Option C — Tools that almost fit but don't

- **`ghq`** — clones into a canonical `host/owner/name` path. Doesn't watch, doesn't symlink, doesn't categorise, and the canonical path fights your topical grouping. Not it.
- **`autofs`** — mounts on access. Wrong abstraction; meant for network/removable filesystems.
- **`bindfs` / bind mounts** — have the same problem as symlinks (target move breaks them) plus require root and fstab.
- **`projectile` / `mani` / `gita`** — config-file based, no auto-detect, no symlinks.
- **Nextcloud / Syncthing "favourites"** — not repo-aware.

## Recommendation

Do Option A with a specific, minimal stack:

```
~/repos/github/                  ← real repos live here (flat or grouped, doesn't matter)
~/repos/_links/
  claude-code/                   ← Stow package (bookmark this in Dolphin)
  clients/                       ← Stow package
  research/                      ← Stow package
  _all/                          ← Stow package containing every repo
```

- `systemd.path` unit watches `~/repos/github/` → runs `repo-reconcile.sh`.
- `repo-reconcile.sh`:
  1. For each new `.git/` found, add to `_all/` unconditionally; prompt or rule-match for topical package.
  2. Walk every symlink under `~/repos/_links/`, test with `[ -e link ]`, and for any dangling one, find the new location by matching `git remote get-url origin` across `~/repos/`, then `stow -R` to re-point.
- Stow handles the actual symlink mechanics, so the script stays trivial.
- The `_links/` tree itself can be a git repo — that version-controls your organisation structure across machines (minus the targets, which are recreated by the reconciler on first run).

And layer **zoxide** on top for terminal/Claude jumps — it's complementary, not competing, and takes 30 seconds to install.

## Open Questions

- Do you want the reconciler to be interactive on new-repo birth, or purely rule-based (e.g. "if repo name contains `claude` → `claude-code/` package")?
- Should `_links/` live in Dolphin's Places panel as a single entry, with users drilling into subcategories, or should each category be pinned separately?

## Sources

- [GNU Stow](https://www.gnu.org/software/stow/)
- [systemd.path units](https://www.freedesktop.org/software/systemd/man/systemd.path.html)
- [inotifywait (inotify-tools)](https://github.com/inotify-tools/inotify-tools)
- [zoxide](https://github.com/ajeetdsouza/zoxide)
- [fzf](https://github.com/junegunn/fzf) · [fd](https://github.com/sharkdp/fd)
- [ghq](https://github.com/x-motemen/ghq)
