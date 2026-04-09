#let space-indigo = rgb("#2B304D")
#let coral = rgb("#F58258")
#let rosewood = rgb("#AA697D")
#let grape = rgb("#5F4FA2")

#set page(
  paper: "a4",
  margin: (x: 2cm, y: 2.2cm),
  footer: context [
    #set text(size: 8pt, fill: rgb("#555"))
    #grid(
      columns: (1fr, 1fr, 1fr),
      align: (left, center, right),
      [Document: Daniel Rosehill],
      [#counter(page).display()],
      [09/04/26],
    )
  ],
)

#set text(font: "IBM Plex Sans", size: 10pt, fill: black)
#set par(justify: true, leading: 0.65em)

#show heading.where(level: 1): it => [
  #set text(fill: space-indigo, size: 20pt, weight: "bold")
  #block(below: 0.8em)[#it.body]
  #block(above: 0em, below: 1.2em)[
    #line(length: 100%, stroke: 2pt + coral)
  ]
]
#show heading.where(level: 2): it => [
  #set text(fill: space-indigo, size: 14pt, weight: "bold")
  #block(above: 1.2em, below: 0.5em)[#it.body]
]
#show heading.where(level: 3): it => [
  #set text(fill: grape, size: 11pt, weight: "bold")
  #block(above: 0.9em, below: 0.3em)[#it.body]
]

#show link: it => text(fill: rosewood, underline(it))
#show raw.where(block: false): it => box(
  fill: rgb("#F3F1EE"), inset: (x: 3pt, y: 1pt), outset: (y: 2pt), radius: 2pt,
)[#text(font: "IBM Plex Mono", size: 8.5pt)[#it]]
#show raw.where(block: true): it => block(
  fill: rgb("#F7F5F1"), inset: 8pt, radius: 3pt, width: 100%,
)[#text(font: "IBM Plex Mono", size: 8pt)[#it]]

#align(center)[
  #text(size: 22pt, weight: "bold", fill: space-indigo)[
    Managing a Large Personal GitHub Repo Fleet
  ]
  #v(0.2em)
  #text(size: 13pt, fill: rosewood)[Synthesis & Recommendation]
  #v(0.4em)
  #text(size: 9pt, fill: rgb("#666"))[Research iteration — 09 April 2026]
]

#v(1em)

= The problem, restated

Daniel manages hundreds of personal GitHub repos, mostly under #raw("~/repos/github/"). Pain points:

+ The flat dump becomes unmanageable; topical subfolders help but *break Dolphin bookmarks* every time they're reorganised.
+ The organisation structure itself is not version-controlled — it can't easily be replicated on another machine.
+ Navigation wastes time: the same ~10 repos are used 99% of the time, but finding them is slow.
+ Common actions (open in Claude Code, terminal, IDE, file manager) are repetitive and unshortcutted.
+ Laptop clones drift badly behind desktop because one-by-one cloning is impractical.
+ Bulk lifecycle ops (delete local, delete remote, prune orphans, clone missing) have no good home.
+ Data-loss protection is non-negotiable for any bulk sync.

= The key insight

*Stop treating the filesystem as the index.* Every approach that keyed organisation on paths — symlink farms, bookmarks, topical subfolders — was fighting the fact that paths are unstable. The moment you accept that *#raw("git remote get-url origin") is the only stable identity*, every downstream problem simplifies:

- Claude can reorganise #raw("~/repos/github/") freely; nothing downstream breaks.
- Dolphin bookmarks become obsolete — replaced by a search-first launcher.
- Multi-machine sync becomes a manifest reconcile, not a path-tree copy.
- Grouping moves out of the filesystem entirely — into *GitHub Projects*, which Daniel already curates.
- Frecency (#raw("open_count") per repo) solves the "10 daily + hundreds periodic" split without manual pinning.

One index keyed on remote URL. Multiple front ends and sync tools reading it. That is the architecture.

= Research summary

#table(
  columns: (auto, 1fr, 2fr),
  stroke: 0.5pt + rgb("#CCC"),
  fill: (col, row) => if row == 0 { space-indigo } else if calc.odd(row) { rgb("#F7F5F1") } else { white },
  inset: 6pt,
  table.header(
    [#text(fill: white, weight: "bold")[No.]],
    [#text(fill: white, weight: "bold")[Question]],
    [#text(fill: white, weight: "bold")[Conclusion]],
  ),
  [1], [Fluid ways to organise repos + version-control structure?], [Manifest-driven layout + symlink farm is possible but brittle; points toward a DB approach.],
  [2], [DB-backed repo manager with semantic search?], [No turnkey tool. Stack: SQLite + sqlite-vec + watchdog + fastembed + Textual TUI. Identity = remote URL hash.],
  [3], [Existing auto-symlink tool that survives moves?], [No. Closest: systemd.path + GNU Stow + reconcile script. Symlinks are the wrong primitive — reframed the problem.],
  [4], [Search-first launcher with action hotkeys?], [Right reframe. SQLite index + fzf/Albert launcher + per-result action hotkeys. GitHub Projects supplies grouping for free.],
  [5], [Existing "GitHub fleet manager" tools?], [No single tool. Closest: ogit + gh-gr + repo-hub + reporemover.xyz. Real ~500 LOC gap in the ecosystem.],
  [6], [Multi-machine clone-set sync with data-loss protection?], [*git-repo-manager (GRM)* is purpose-built and the only tool with built-in uncommitted-change safety.],
  [7], [GUI runner for repos?], [No turnkey tool but 15-minute Rofi+SQLite script hits it; Albert is the polished version. Same index as everything else.],
)

= The recommended architecture

Five layers, all keyed on remote URL, each independently replaceable.

```
┌──────────────────────────────────────────────────────────────┐
│  GUI RUNNER         Rofi (today) → Albert (v2)               │ ← Meta+R
│   ↓ reads                                                    │
│  INDEX              ~/.local/share/repo-index.db (SQLite)    │
│   ↑ populated by                                             │
│  SOURCES  ┌─ gh repo list         (remote inventory)         │
│           ├─ gh project item-list (topical grouping)         │
│           └─ fd + systemd.path    (local clone discovery)    │
│                                                              │
│  CLONE-SET SYNC     git-repo-manager (GRM)                   │ ← cross-machine
│   ↑ driven by                                                │
│  MANIFEST           ~/repos-manifest/config.toml             │
│   ↑ regenerated from gh repo list, committed, pushed         │
└──────────────────────────────────────────────────────────────┘
```

== Layer 1 — Identity

#raw("remote_url") is the primary key everywhere. Never a filesystem path. This is the load-bearing decision.

== Layer 2 — The index

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
  dirty       INTEGER DEFAULT 0
);
```

Populated by a ~80-line Python script on an hourly timer:

+ #raw("gh repo list") → upsert metadata.
+ #raw("gh project item-list") → join on repo URL, fill #raw("projects").
+ #raw("fd") walk + #raw("git remote get-url origin") → fill #raw("local_path") by matching remote URL. *Survives moves automatically.*
+ #raw("git status --porcelain") → cache #raw("dirty").

Plus a #raw("systemd.path") watcher on #raw("~/repos/github/") for near-real-time updates.

== Layer 3 — The GUI runner

*Week 1:* Rofi + 50-line shell script bound to #raw("Meta+R"). Fuzzy match on name, order by #raw("open_count DESC"), per-result hotkeys:

- #raw("Enter") → Claude Code in Konsole
- #raw("Alt+T") → terminal only
- #raw("Alt+C") → Claude + terminal side-by-side
- #raw("Alt+V") → VS Code
- #raw("Alt+F") → Dolphin
- #raw("Alt+G") → GitHub page in browser
- #raw("Alt+N") → clone uncloned repo into #raw("~/repos/github/_inbox/")
- Every action bumps #raw("open_count") and #raw("last_opened")

*Later:* port to Albert Python extension. Same DB, better action UX.

== Layer 4 — Clone-set sync across machines (GRM)

- #raw("~/repos-manifest/") is a private GitHub repo containing #raw("config.toml").
- *Desktop weekly cron* regenerates #raw("config.toml") from #raw("gh"), commits diffs, pushes.
- *Laptop alias* #raw("repos-sync"): pulls manifest, runs #raw("grm repos status"), prompts, then #raw("grm repos sync"). GRM refuses to touch dirty worktrees — data-loss protection satisfied.

== Layer 5 — Bulk lifecycle ops

- *Delete local:* #raw("Alt+D") → confirm → #raw("rm -rf") + clear #raw("local_path").
- *Delete remote:* kept out of the runner. Use reporemover.xyz for sweeps.
- *Clone missing:* #raw("Alt+N") for single repos; GRM sync for bulk.
- *Bulk pull:* #raw("grm repos sync") (safe) or #raw("gh-gr pull") (faster, less safe).
- *Bulk push:* deliberately not automated — footgun.
- *Dirty view:* #raw("dirty=1") filter in Rofi, or repo-hub TUI.

= Top-level thoughts

+ *The ecosystem genuinely lacks this tool.* No single product does what Daniel wants. The glue combining GRM + ogit + Rofi/Albert + GitHub Projects is a plausible ~500 LOC open-source project.
+ *GRM is the only non-negotiable third-party dependency.* Its uncommitted-change safety model is not reproducible in a weekend script, and the multi-machine use case is the one with real data-loss risk.
+ *GitHub Projects is the under-used pillar.* It turns existing curation into the grouping layer for free, eliminating the "version-control the folder tree" sub-problem.
+ *Frecency beats manual favourites.* #raw("ORDER BY open_count DESC") is self-maintaining and reflects real usage.
+ *Ship Rofi today, not Albert next month.* The 15-minute script is a daily driver that stops the pain now, using the same DB the polished version will use.
+ *The #raw("_inbox/") convention matters.* Point GitKraken's default clone path there so new repos land somewhere the watcher can pick up and the runner can triage.

= Concrete next steps

+ *Today (15 min):* create empty #raw("~/.local/share/repo-index.db"), write the Rofi script, bind #raw("Meta+R").
+ *Today (30 min):* write the hourly cron script (#raw("gh repo list") + #raw("fd") + match by remote URL).
+ *This week:* install GRM, generate manifest, create #raw("daniel-repos-manifest") private repo, add weekly regen cron.
+ *Next laptop session:* clone manifest, add #raw("repos-sync") alias, run it.
+ *Add GitHub Projects sync* once steps 1–4 are stable.
+ *Next weekend:* port runner to Albert.
+ *Later:* consider publishing the glue as OSS.

= What was deliberately not solved

- *Semantic search over README contents.* Premature — fuzzy on name + description + topics + projects covers 99%.
- *KRunner integration.* Plasma 6 Python runner template still shaky.
- *Uncloned-but-searchable repos.* Week 2, not week 1.
- *Bulk destructive ops.* Deliberately kept out of daily tooling.

= Primary tools referenced

- #link("https://github.com/hakoerber/git-repo-manager")[git-repo-manager (GRM)]
- #link("https://github.com/davatorium/rofi")[Rofi] · #link("https://github.com/lbonn/rofi")[rofi-wayland]
- #link("https://albertlauncher.github.io/")[Albert launcher]
- #link("https://cli.github.com/")[GitHub CLI]
- #link("https://github.com/wmalik/ogit")[ogit] · #link("https://github.com/sarumaj/gh-gr")[gh-gr] · #link("https://github.com/daffyzk/repo-hub")[repo-hub]
- #link("https://www.freedesktop.org/software/systemd/man/systemd.path.html")[systemd.path] · #link("https://github.com/sharkdp/fd")[fd] · #link("https://github.com/ajeetdsouza/zoxide")[zoxide]
