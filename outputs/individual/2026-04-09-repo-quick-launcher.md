# Repo Quick-Launcher with Action Menu

## Key Findings

No single off-the-shelf tool bundles "fuzzy-find a repo + present an action menu + multiplex Claude/terminal/files in a tiled window" on KDE Wayland. But every piece exists and the glue is ~40 lines of bash. Easiest route: a small shell function wrapping `fd` (find repo) + `fzf` (pick if ambiguous) + a `case` menu, with `zellij` (or `tmux`) handling the multiplex option.

## The stack (all already-packaged tools)

| Need | Tool | Why |
|---|---|---|
| Find repo by fuzzy name | `fd` + `fzf` | Fast, handles "my weird prompts" → `my-weird-prompts` |
| Action menu | bash `select` or `fzf` | `select` is built-in and gives exactly the numeric list you described |
| Open in Claude Code | `claude` CLI | Already installed |
| Open in file manager | `dolphin <path>` | KDE default |
| Open in VS Code | `code <path>` | Already installed |
| Open in terminal | `konsole --workdir <path>` | KDE default |
| Tiled multiplex | `zellij` **or** `tmux` **or** `konsole --split-view` | See below |

## Multiplex option — pick one

1. **Zellij** (recommended) — modern, declarative layouts via KDL. One layout file defines the three panes (Claude / Dolphin-in-terminal view / shell). Launch: `zellij --layout repo.kdl`. Easiest for "always same tiled presentation."
2. **tmux** — same idea, more ubiquitous, layout via `tmux new-session \; split-window \; ...`.
3. **Konsole split view** — native KDE, but scripting splits is clunkier than zellij/tmux. Skip unless you want zero new deps.

Note: a GUI file manager (Dolphin) can't live *inside* a terminal multiplexer pane. For a true tiled window with Dolphin + Claude + terminal side-by-side you need a **window-manager-level** tile, not a terminal multiplexer. Two realistic options:

- **KWin scripting / kstart + window rules**: launch Dolphin, Konsole-running-claude, and Konsole-shell, then use `kwin --replace` scripts or `wmctrl`/`kdotool` to place them. Fiddly on Wayland.
- **Compromise**: run everything inside one Konsole window using zellij/tmux panes (Claude + shell + `ranger`/`yazi` as the "file manager"). Much simpler, 100% reliable on Wayland. Recommended.

## Minimal implementation

Drop this in `~/.config/fish/functions/openrepo.fish` or `~/.bashrc`:

```bash
openrepo() {
  local query="$*"
  local root="$HOME/repos"
  # Find candidate repo dirs (any .git parent) matching the query loosely
  local slug
  slug=$(echo "$query" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
  local match
  match=$(fd -t d -H '^\.git$' "$root" -x dirname {} \
          | fzf --filter="$slug" | head -n1)
  if [[ -z "$match" ]]; then
    # fallback: interactive fuzzy pick
    match=$(fd -t d -H '^\.git$' "$root" -x dirname {} | fzf)
  fi
  [[ -z "$match" ]] && { echo "No repo found for: $query"; return 1; }

  echo "Repo: $match"
  PS3=$'\nChoose action: '
  select action in \
      "Open in Claude Code" \
      "Open in File Manager" \
      "Open in VS Code" \
      "Open at Terminal" \
      "Multiplex (Claude + Files + Terminal)" \
      "Cancel"; do
    case $REPLY in
      1) (cd "$match" && claude) ; break ;;
      2) dolphin "$match" & disown ; break ;;
      3) code "$match" & disown ; break ;;
      4) konsole --workdir "$match" & disown ; break ;;
      5) konsole --workdir "$match" -e zellij --layout ~/.config/zellij/repo.kdl & disown ; break ;;
      6) break ;;
    esac
  done
}
```

Zellij layout `~/.config/zellij/repo.kdl`:

```kdl
layout {
  pane split_direction="vertical" {
    pane command="claude"
    pane split_direction="horizontal" {
      pane command="yazi"   // terminal file manager
      pane                  // plain shell
    }
  }
}
```

Usage:

```
$ openrepo my weird prompts
Repo: /home/daniel/repos/github/project/my-weird-prompts
1) Open in Claude Code
2) Open in File Manager
3) Open in VS Code
4) Open at Terminal
5) Multiplex (Claude + Files + Terminal)
6) Cancel
Choose action: 1
```

That's exactly the flow described.

## "From a chatbox" variant

If you also want to invoke this from a non-terminal UI (e.g. KRunner, rofi, or an AI chat), wrap the same logic in a script and:

- **KRunner**: create a `.desktop` file with `Exec=konsole -e openrepo %u` — then Alt+Space → type "openrepo my weird prompts".
- **Rofi**: `rofi -dmenu -p "openrepo"` piped into the function.
- **From Claude Code / an MCP chat**: expose as a tiny local MCP tool that shells out to the same function. Overkill unless you're already in that surface.

## Recommendation

1. Install `fd`, `fzf`, `zellij`, `yazi` (`apt install fd-find fzf; cargo install zellij yazi-fm` or use the `.deb`s).
2. Paste the `openrepo` function above.
3. Accept the compromise that "file manager" inside the multiplex is a TUI (`yazi`), not Dolphin — this is the only way to get a reliable tiled presentation on Wayland without fighting KWin.
4. Keep option 2 ("Open in File Manager") as the escape hatch that launches the real Dolphin window.

Total effort: ~15 minutes. No bespoke tool needed.

## Sources

- `fzf` README — github.com/junegunn/fzf
- `zellij` layouts docs — zellij.dev/documentation/layouts.html
- `yazi` (terminal file manager) — yazi-rs.github.io
- bash `select` builtin — GNU Bash Reference Manual, §3.2.5.2
- KDE Konsole CLI flags — `man konsole` (`--workdir`, `-e`)
- Wayland window-placement limitations — KDE community wiki notes on KWin scripting under Wayland
