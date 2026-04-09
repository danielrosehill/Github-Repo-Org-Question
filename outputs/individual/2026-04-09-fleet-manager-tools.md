# Existing GitHub Repo Fleet Manager Tools

Date: 2026-04-09
Prompt: `prompts/run/subsequent/2026-04-09-fleet-manager-tools.md`

## Verdict

**No single tool hits all 7 requirements.** Closest genuine fit is **ogit** + a bulk-ops helper (**gh-gr** or **reporemover.xyz**), plus **repo-hub/repolice** for dirty-state scanning. There is a real, ~500 LOC gap in the ecosystem here.

## Genuine fits (closest to spec)

**[ogit](https://github.com/wmalik/ogit)** — TUI+CLI, multi-provider (GitHub/GitLab), organises clones under a watched dir, bulk clone by org/filter, browser launcher actions.
Hits: 1 (partial — discovers remotes, organises local), 2 (clone), 6 (partial — browser/URLs).
Gap: no bulk delete, no stale/dirty/orphan views, no favourites/MRU, no fuzzy over topics.

**[gh-gr](https://github.com/sarumaj/gh-gr)** — `gh` extension for managing many repos at once.
Hits: 7 (bulk pull/push), 3 (partial — status across all repos), 2 (partial).
Gap: no TUI selection, no delete, no fuzzy/MRU/launcher.

## Partial fits worth knowing

- **[gh-repo-man](https://github.com/2KAbhishek/gh-repo-man)** — fzf-powered interactive browse+clone with language/archived/fork filters, concurrent cloning, tmux/editor launch. Remote-only; no local reconciliation, no delete, no state views.
- **[gh-reponark](https://github.com/admcpr/gh-reponark)** — Bubble Tea TUI that pulls config for every repo, filters (missing CODEOWNERS, protection off, etc.). Audit axis, not lifecycle.
- **[repo-hub / repolice](https://github.com/daffyzk/repo-hub)** — Rust TUI scanning a dir tree for staged/unstaged status across all clones. **Best tool found for the "dirty clones" view.** Local-only, no remote reconciliation, no ops.
- **[Repo Remover](https://reporemover.xyz/)** — Web app using a token to list/sort/filter and **bulk delete or archive remote repos**. The only non-TUI tool that nails the destructive remote side with multi-select. No local awareness.
- **[github-tui](https://github.com/skanehira/github-tui)** — general GitHub TUI (issues/PRs/repo browse). Wrong axis.

## Ruled out after checking

gh-repo-fzf, gh-star, gh-repo-list, gh-get-repos, rm3l/gh-org-repo-sync, ruralocity/gh-clone-team-repos (single-axis: clone-all or fuzzy-pick, no lifecycle), gh-dep (PR TUI), gh-repo-config / gh-repo-collab / twelvelabs/gh-repo-config / myzkey/gh-repo-settings (settings/YAML, not lifecycle), mislav/gh-delete-repo (deprecated, single-repo).

## Honest conclusion

Two-tool combos worth actually trying:

1. **ogit** (inventory + clone + launcher) + **gh-gr** (bulk pull/status) + **reporemover.xyz** for occasional remote-delete sweeps.
2. Write a thin Bubble Tea / Textual wrapper around `gh api user/repos` + a watched dir walk + `git status --porcelain`. Closest forkable prior art: **ogit** (Go, provider inventory + TUI) or **repo-hub** (Rust, local dirty scanning).

Given the 2025–2026 Charm/Textual surge, this is a plausible weekend OSS project — and a tool Daniel is clearly not the only person who wants.

## Sources

- [wmalik/ogit](https://github.com/wmalik/ogit)
- [2KAbhishek/gh-repo-man](https://github.com/2KAbhishek/gh-repo-man)
- [admcpr/gh-reponark](https://github.com/admcpr/gh-reponark)
- [daffyzk/repo-hub](https://github.com/daffyzk/repo-hub)
- [sarumaj/gh-gr](https://github.com/sarumaj/gh-gr)
- [Repo Remover](https://reporemover.xyz/)
- [skanehira/github-tui](https://github.com/skanehira/github-tui)
- [rothgar/awesome-tuis](https://github.com/rothgar/awesome-tuis)
