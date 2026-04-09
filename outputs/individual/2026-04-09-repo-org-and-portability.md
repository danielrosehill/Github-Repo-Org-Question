# Repo Organisation & Portability — Initial Ideas

Date: 2026-04-09
Prompt: `prompts/run/initial/2026-04-09-repo-org-and-portability.md`

## Key Findings

Four approaches, roughly ordered from lightest to most structured.

### 1. Symlink farm (fixes the bookmark problem)

Keep repos physically grouped in topical subfolders, but maintain a flat `~/repos/github/_flat/` directory of symlinks pointing to them. Bookmark the flat view in Dolphin — links never break when you reorganise, because the symlinks are regenerated from a manifest. A tiny script rebuilds `_flat/` from the current tree.

### 2. Manifest-driven layout (version-controllable)

A single YAML/JSON file is the source of truth:

```yaml
- repo: git@github.com:me/foo.git
  group: claude-code
- repo: git@github.com:me/bar.git
  group: israeli-prep
```

One script reads it and:

- clones missing repos into the right subfolder
- moves existing ones if `group:` changed
- regenerates the `_flat/` symlink farm
- regenerates Dolphin "Places" bookmarks (they live in `~/.local/share/user-places.xbel` — editable XML)

Commit the manifest to a small repo (the existing `indexing-repos/` area fits naturally). On a new machine: clone the manifest repo, run the script, done. Since the manifest lists *all* repos you care about (not just currently cloned), it doubles as a "replicate on another machine" tool — the script just skips or clones as needed.

### 3. Dolphin bookmarks specifically

Bookmarks break because they're absolute paths. Two fixes:

- Point bookmarks at stable `_flat/` symlinks (approach 1).
- Or have the reorg script rewrite `~/.local/share/user-places.xbel` in place when it moves a repo — it's just XML with `<bookmark href="file:///...">` entries.

### 4. Off-the-shelf tools

- **`ghq`** (https://github.com/x-motemen/ghq) — closest off-the-shelf fit: `ghq get` clones into a predictable path, `ghq list` enumerates, scriptable. But it enforces its own `host/user/repo` layout, which fights topical grouping.
- **`myrepos` (`mr`)** — good for bulk `git pull` across many repos, doesn't solve layout.
- A ~100-line Python script around a manifest beats these for this specific use case.

## Recommendation

Combine approaches 2 + 1:

- **Manifest in a git repo** = portable structure, single source of truth.
- **Symlink farm** = bookmarks that survive reorganisation.
- Claude handles the grouping (the existing `organise-github-repos` skill), and the manifest-sync script runs afterwards to record the new layout and rebuild symlinks.

## Open Questions

- Should the manifest live inside `indexing-repos/` or as its own small repo?
- Do we want per-machine overrides (e.g. some repos only cloned on the workstation, not the laptop)?
- Should GitKraken's default clone path be redirected into a `_inbox/` folder so new clones land somewhere obvious before being filed?

## Sources

Reasoning from first principles plus prior knowledge of `ghq`, `myrepos`, and the KDE `user-places.xbel` format. No web sources consulted for this initial pass.
