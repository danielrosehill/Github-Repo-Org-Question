# Multi-Machine Clone-Set Sync

Date: 2026-04-09
Prompt: `prompts/run/subsequent/2026-04-09-multi-machine-sync.md`
Builds on: `outputs/individual/2026-04-09-fleet-manager-tools.md`

## Key Findings

This problem **does** have purpose-built tools, unlike the launcher/fleet-manager question. The category is usually called "declarative multi-repo management" or "workspace manifest tools." The trick is picking one whose safety model matches your data-loss requirement.

## Genuine fits

### [git-repo-manager (GRM)](https://github.com/hakoerber/git-repo-manager) — **top pick**

Hakoerber's tool. Explicitly designed for this workflow.

- **Manifest-driven:** a TOML/YAML file lists every repo, its remote, and its worktree path.
- **`grm repos sync`** reconciles the local tree to the manifest: clones missing, reports drift.
- **Safety by default:** refuses to touch worktrees with uncommitted changes or unpushed commits unless forced. This is exactly the data-loss protection you asked for.
- **GitHub/GitLab discovery:** `grm repos find github <user>` generates the manifest automatically from your GitHub account — you don't hand-maintain it.
- **Committable:** the manifest is a plain file meant to live in a git repo.
- **Worktree support** if you want fancy multi-branch checkouts per repo.

Workflow on laptop: `git pull` the manifest repo → `grm repos sync config.toml` → done. New machine: same.

### [ghorg](https://github.com/gabrie30/ghorg)

Mass-clones and keeps-in-sync every repo in a GitHub user/org. Not manifest-driven — it takes the live list from GitHub as the source of truth.

- **`ghorg clone <user> --preserve-dir`** on the laptop pulls down everything you own, updates existing clones.
- **`--prune`** removes local clones no longer on remote (opt-in, with `--prune-no-confirm` for automation — leave that off).
- Does **not** have GRM's uncommitted-change safety net by default; relies on git refusing fast-forwards when there's conflict. Read the docs carefully before using `--prune`.
- Simpler mental model than GRM: "make local match GitHub" vs GRM's "make local match manifest."

### [mr (myrepos)](https://myrepos.branchable.com/)

Venerable. `.mrconfig` lists repos; `mr update` runs `git pull` across all of them; `mr fetch`, `mr status`, etc. Pre-existing clones only — no GitHub discovery. Pair with `gh repo list` to generate the config.

## Partial fits

- **[mani](https://manicli.com/)** — YAML of repos, bulk commands, tag-scoped execution. Good for "run `git pull` across all repos with tag `work`" but not a sync tool in the reconcile sense.
- **[gita](https://github.com/nosarthur/gita)** — multi-repo status/exec. `gita ll` is a lovely colour-coded status view. Not reconcile-driven.
- **[gh-gr](https://github.com/sarumaj/gh-gr)** — gh extension for bulk pull/push across many repos. Great companion, not a replacement.

## Honest recommendation

**Use GRM as the reconcile engine.** It is the only tool of the bunch whose safety model explicitly protects uncommitted changes and unpushed commits, which is your hard requirement.

### Setup

1. On the desktop, one-time: `grm repos find config github --token $(gh auth token) --owner danielrosehill > ~/repos-manifest/config.toml`
2. Create `~/repos-manifest/` as its own git repo. Commit `config.toml`. Push to a private GitHub repo (e.g. `daniel-repos-manifest`).
3. **Weekly cron on the desktop** that regenerates `config.toml` from GitHub (`grm repos find config ...`), diffs, commits if changed, pushes. This keeps the tree up to date automatically as you create/archive/rename repos.
4. On the laptop: clone the manifest repo once; add a shell alias `repos-sync = 'cd ~/repos-manifest && git pull && grm repos sync config.toml'`. Run it whenever you sit down at the laptop.

### Bulk pull / push

- **Bulk pull:** `grm repos sync` already fetches and updates clean worktrees; leaves dirty ones alone.
- **Bulk push:** GRM doesn't push. Pair with `gh-gr push` or `gita super push` for the rare case you actually want to push across many repos at once. (Realistically you'll almost never want this — it's a footgun. Push per-repo from the launcher.)

### Data-loss safety checklist

- GRM refuses to touch dirty worktrees → safe by default.
- **Never use `ghorg --prune` or any "force" flag in your cron.** Prune only interactively.
- Before sync on the laptop, run `gita ll` (or `grm repos status`) to see what's dirty, so you can deal with it before reconcile touches anything. Add this to the alias.
- Keep a `grm repos status --json > /tmp/pre-sync.json` snapshot before every sync on laptop; diff after. Cheap audit trail.

### Upgraded alias

```bash
repos-sync() {
  cd ~/repos-manifest || return
  git pull --ff-only || { echo "manifest pull failed"; return 1; }
  grm repos status config.toml   # show dirty repos first
  read -p "Proceed with sync? [y/N] " ans
  [[ "$ans" == "y" ]] || return
  grm repos sync config.toml
}
```

## How this composes with earlier outputs

- The **SQLite launcher index** (from the search-first launcher output) and the **GRM manifest** are two views of the same fact — "repos I care about." Generate both from the same `gh repo list` call.
- GRM owns the *clone-set* layer. The launcher owns the *find-and-open* layer. The GitHub Projects integration owns the *grouping* layer. All three key off remote URL, all three survive filesystem reorganisation.
- The manifest repo is also the natural home for the launcher's exported favourites and MRU, so those travel between machines too.

## Open Questions

- Should the desktop's weekly manifest-regen cron also auto-archive repos that haven't been touched in N months? Probably no — too much policy in automation, too easy to lose context.
- Should GRM's output dir structure mirror the topical grouping (`claude-code/`, `clients/`, …)? Given earlier conclusions (filesystem layout should be irrelevant), probably use a flat `~/repos/github/<name>` and let the launcher handle grouping.
- Is there a way to exclude huge repos (models, datasets) from laptop sync to save disk? GRM supports per-repo `clone: false` or tags — investigate.

## Sources

- [git-repo-manager (GRM)](https://github.com/hakoerber/git-repo-manager) · [GRM docs](https://hakoerber.github.io/git-repo-manager/)
- [ghorg](https://github.com/gabrie30/ghorg)
- [myrepos (mr)](https://myrepos.branchable.com/)
- [mani](https://manicli.com/)
- [gita](https://github.com/nosarthur/gita)
- [gh-gr](https://github.com/sarumaj/gh-gr)
