# DB-Backed Repo Manager — Research Report

Date: 2026-04-09
Prompt: `prompts/run/subsequent/2026-04-09-db-backed-repo-manager.md`
Builds on: `outputs/individual/2026-04-09-repo-org-and-portability.md`

## Key Findings

Nothing off-the-shelf covers all six requirements (DB-backed, auto-detect on birth, survives moves, tags/notes, semantic search, launcher actions). You'll be gluing — but the glue is small, and the stack in 2026 is quite pleasant.

## 1. Existing tools (vs the 6 requirements)

| Tool | What it does | Local DB | Survives moves | Semantic search | Gap |
|---|---|---|---|---|---|
| [ghq](https://github.com/x-motemen/ghq) + fzf | Clones into canonical `host/owner/name` path, lists them | No — pure filesystem | No (path IS the key) | No | Fails auto-detect & move-survival outright |
| [gita](https://github.com/nosarthur/gita) | Multi-repo status/exec, groups in a text file | Flat file | Paths editable | No | No auto-discover, no semantic |
| [mani](https://manicli.com/) | YAML-driven repo runner with tags/projects | YAML | Yes (paths in YAML) | No | No auto-detect, no DB, no launcher actions |
| grm / gitrepos | Declarative config | Config file | Yes | No | Same gaps as mani |
| [projectable](https://github.com/dzfrias/projectable) | TUI project manager | No | N/A | No | Per-project only |
| [Sourcegraph self-hosted](https://sourcegraph.com) | Full code index + semantic | Postgres + Zoekt | Yes | Yes (code-level) | Heavy Docker stack; overkill for repo-list UX; free tier shrank |
| JetBrains / VS Code "Project Manager" ext | IDE-scoped project list | JSON | Yes | No | IDE-locked, no auto-watch |
| KRunner recent docs / Kickoff | System launcher | — | — | No | Not repo-aware |
| [dokosa](https://github.com/sile/dokosa) | Indexes local git repos with vector embeddings | SQLite-ish + vectors | Yes | **Yes** | Search-only — no tags, no launcher, no watcher |
| [semantic-code-search](https://github.com/sturdy-dev/semantic-code-search) | NL search *inside* a repo | Local index | — | Yes | Per-repo, not a fleet manager |

**Closest partials:** `mani` (tags/actions, no DB/watch/semantic) and `dokosa` (semantic over repos, no tags/launcher). Neither is a drop-in.

## 2. Build-your-own stack recommendation

Pragmatic, ~weekend-sized:

- **Index store:** SQLite + [sqlite-vec](https://github.com/asg017/sqlite-vec). One file, trivial backup, composes with normal SQL for tag filters. Export `tags.yaml` + `notes/<id>.md` to a git repo for version control of the *organisation layer*.
- **Stable identity:** hash of the `origin` remote URL (fallback: first-commit SHA). **This is what makes moves safe** — the primary key is never the filesystem path.
- **Embeddings:** `sentence-transformers` (`all-MiniLM-L6-v2` or `bge-small-en-v1.5`), or [`fastembed`](https://github.com/qdrant/fastembed) for ONNX if you want to avoid torch. Index: repo name + description + topics + first 2–4 KB of README.
- **Watcher:** Python [`watchdog`](https://github.com/gorakhargosh/watchdog) (inotify backend). Watch `~/repos/` recursively; when a new `.git/` dir appears, insert a row and enqueue an embedding job. Run a periodic reconcile that matches rows to paths **by remote URL**, so manual moves are auto-healed.
- **UI:** [Textual](https://textual.textualize.io/) TUI ships fastest; PySide6 if you want native KDE feel later.
- **Launcher actions:** plain `subprocess.Popen`:
  - Terminal: `konsole --workdir <path>`
  - Claude: `konsole -e bash -c "cd <path> && claude"`
  - Dolphin: `dolphin <path>`
  - VS Code: `code <path>`
  - GitKraken: `gitkraken --path <path>`

## 3. Semantic search specifics (2026)

**Pick sqlite-vec.** Reasons for a single-user desktop tool indexing a few thousand READMEs:

- One file alongside the metadata DB — no daemon, no second store.
- `vec0` virtual tables do brute-force + filtered ANN, more than fast enough under ~10k vectors.
- Composes with normal SQL: `WHERE tags LIKE '%claude%' ORDER BY distance` in one query.

When *not* to pick it:

- **LanceDB** is the right answer if you grow into code-chunk-level search (millions of vectors) or want columnar analytics. [Lance + DuckDB](https://lancedb.com/blog/newsletter-january-2026/) is the 2026 power-user combo — unnecessary here.
- **Chroma** is fine but heavier and the ecosystem has cooled relative to sqlite-vec / LanceDB.
- **DuckDB VSS** works but mixes two embedded DBs for no gain.

## 4. KRunner integration on Plasma 6

A KRunner runner is still the right "type anywhere to jump to repo" path on Plasma 6. Options:

- **Native C++ runner** using the [KRunner framework](https://develop.kde.org/docs/plasma/krunner/) — most robust; [community template exists](https://discuss.kde.org/t/krunner-plugin-template-for-plasma-6-x/18071).
- **Python D-Bus runner** — implement the `org.kde.krunner1` D-Bus interface in Python, ship a `.service` + `.desktop`. This is how most third-party Plasma 6 Python runners work now. [`krunner-bridge`](https://github.com/Shihira/krunner-bridge) still works but is a Plasma 5–era shim; writing a small D-Bus runner directly is cleaner.
- **Cheapest MVP:** skip KRunner initially. Bind a global KWin shortcut to open the Textual TUI. Upgrade to a real runner once the tool proves itself.

**Uncertain:** the maintenance state of Plasma 6 Python D-Bus runner templates — verify before committing.

## Recommendation

1. **MVP (weekend):** Python + `watchdog` + SQLite + sqlite-vec + fastembed + Textual TUI. Identity = hash of `origin` URL. Global shortcut launches the TUI.
2. **v2:** Export tags/notes to a git repo so the organisation layer is portable across machines — this subsumes the "manifest" idea from the first output.
3. **v3:** KRunner runner for system-wide invocation.
4. Keep GitKraken's default clone dir as `~/repos/github/_inbox/` so new repos land in an obvious place the watcher can pick up, then get filed (or not — filing becomes cosmetic once the DB is source of truth).

## Open Questions

- Should the org-layer export repo live inside existing `indexing-repos/`?
- Do we want per-machine overrides (some repos only cloned on workstation, not laptop)?
- Is there value in also indexing *uncloned* GitHub repos (via `gh repo list`) so semantic search covers the full set, and the launcher offers "clone into inbox" as an action?

## Sources

- [ghq](https://github.com/x-motemen/ghq)
- [gita](https://github.com/nosarthur/gita)
- [mani](https://manicli.com/)
- [projectable](https://github.com/dzfrias/projectable)
- [dokosa — semantic search over local git repos](https://github.com/sile/dokosa)
- [sturdy-dev/semantic-code-search](https://github.com/sturdy-dev/semantic-code-search)
- [sqlite-vec](https://github.com/asg017/sqlite-vec)
- [sqlite-vec overview](https://dev.to/aairom/embedded-intelligence-how-sqlite-vec-delivers-fast-local-vector-search-for-ai-3dpb)
- [LanceDB](https://www.lancedb.com/)
- [Lance × DuckDB, Jan 2026](https://lancedb.com/blog/newsletter-january-2026/)
- [Embedded DBs comparison](https://thedataquarry.com/blog/embedded-db-1/)
- [KRunner dev docs (Plasma 6)](https://develop.kde.org/docs/plasma/krunner/)
- [Plasma 6 KRunner template thread](https://discuss.kde.org/t/krunner-plugin-template-for-plasma-6-x/18071)
- [krunner-bridge](https://github.com/Shihira/krunner-bridge)
- [watchdog](https://github.com/gorakhargosh/watchdog)
- [fastembed](https://github.com/qdrant/fastembed)
- [Textual](https://textual.textualize.io/)
