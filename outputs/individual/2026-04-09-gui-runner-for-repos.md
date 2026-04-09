# GUI Runner for Repos

Date: 2026-04-09
Prompt: `prompts/run/subsequent/2026-04-09-gui-runner-for-repos.md`

## Verdict

**No turnkey tool exists** that hits all four requirements (base-path scoping + fuzzy + frecency bias + per-result action hotkeys) as a single install. But the gap is small — ~50 lines of script hosted inside an existing GUI runner. Three viable hosts, ordered by shortest-path-to-working.

## Closest turnkey partials

- **[sesh](https://github.com/joshmedeski/sesh)** — tmux session manager, fuzzy-searches directories with zoxide frecency built in. If you lived in tmux this would be 90% of the answer. No GUI runner popup; no per-result action hotkeys beyond "attach session." Worth knowing about.
- **[zoxide](https://github.com/ajeetdsouza/zoxide) + `zi`** — CLI frecency jumper. Not a GUI runner. Complementary for terminal use, not a replacement.
- **Albert's Files extension** — can fuzzy-index a base path. No frecency bias, no per-result action hotkeys beyond Albert's default Enter/Shift+Enter/Ctrl+Enter triad.
- **Ulauncher File Search extension** — same shape, same gap.
- **KRunner built-in** — can match directory names but has no way to scope to a base path, no frecency, no custom per-result actions without writing a runner.

None are turnkey. Every one of them would need scripting on top to add frecency + the four-action hotkey set.

## Host launcher — shortest path to working

### Option 1: Rofi + script (15 minutes, ugly but works)

```bash
#!/usr/bin/env bash
# ~/.local/bin/repo-runner — bind to Meta+R in KWin
DB=~/.local/share/repo-index.db
sqlite3 "$DB" <<'SQL' > /tmp/repos.list
SELECT printf('%s\t%s\t%s', name, local_path, remote_url)
FROM repos
WHERE local_path IS NOT NULL
ORDER BY open_count DESC, last_opened DESC NULLS LAST, name;
SQL

sel=$(rofi -dmenu -i -p "repo" \
  -kb-custom-1 'Alt+t' \
  -kb-custom-2 'Alt+v' \
  -kb-custom-3 'Alt+f' \
  -kb-custom-4 'Alt+c' \
  -format 'i:s' \
  < <(cut -f1 /tmp/repos.list))

key=$?
[ -z "$sel" ] && exit 0
idx="${sel%%:*}"
line=$(sed -n "$((idx+1))p" /tmp/repos.list)
path=$(cut -f2 <<<"$line")
url=$(cut -f3 <<<"$line")

case "$key" in
  10) konsole --workdir "$path" ;;                                   # Alt+t
  11) code "$path" ;;                                                # Alt+v (IDE)
  12) dolphin "$path" ;;                                             # Alt+f
  13) konsole --workdir "$path" --new-tab -e claude ;;               # Alt+c (both)
  *)  konsole --workdir "$path" -e bash -c 'claude; exec bash' ;;    # Enter
esac

sqlite3 "$DB" "UPDATE repos SET open_count = open_count + 1,
  last_opened = datetime('now') WHERE remote_url = '$url';"
```

Bind `Meta+R` → this script in System Settings → Shortcuts → Custom Shortcuts. Done. Rofi gives you:

- Base-path scoping (SQL filter).
- Fuzzy match (`-i`, and `-matching fuzzy`).
- Frecency bias (`ORDER BY open_count DESC` in the query).
- Per-result action hotkeys (`-kb-custom-N`).
- A real GUI popup.

This is the **minimum viable GUI runner** and the shortest path from "no tool" to "daily driver."

### Option 2: Albert Python extension (half a day, polished)

Albert is a better long-term host because per-result actions are a first-class concept in its API — each returned `Item` carries an `actions=[...]` list, and Albert renders them as Enter, Shift+Enter, Ctrl+Enter with proper labels. The extension is ~60 lines of Python:

```python
# ~/.local/share/albert/python/plugins/repos/__init__.py
from albert import *
import sqlite3, subprocess, os

md_iid = "2.3"
md_name = "Repos"
md_description = "Fuzzy-open local GitHub repos"
md_id = "repos"

class Plugin(PluginInstance, TriggerQueryHandler):
    def __init__(self):
        PluginInstance.__init__(self)
        TriggerQueryHandler.__init__(self, self.id, self.name,
            self.description, defaultTrigger="r ")

    def handleTriggerQuery(self, query):
        db = sqlite3.connect(os.path.expanduser("~/.local/share/repo-index.db"))
        rows = db.execute("""
            SELECT name, description, local_path, remote_url
            FROM repos
            WHERE local_path IS NOT NULL AND name LIKE ?
            ORDER BY open_count DESC, last_opened DESC
            LIMIT 25
        """, (f"%{query.string}%",)).fetchall()

        for name, desc, path, url in rows:
            query.add(StandardItem(
                id=url, text=name, subtext=desc or path,
                iconUrls=["xdg:folder-git"],
                actions=[
                    Action("claude", "Open in Claude Code",
                        lambda p=path, u=url: self.launch(
                            ["konsole", "--workdir", p, "-e",
                             "bash", "-c", "claude; exec bash"], u)),
                    Action("term", "Open terminal",
                        lambda p=path, u=url: self.launch(
                            ["konsole", "--workdir", p], u)),
                    Action("both", "Claude + terminal",
                        lambda p=path, u=url: self.launch(
                            ["konsole", "--workdir", p, "--new-tab",
                             "-e", "claude"], u)),
                    Action("dolphin", "Open in Dolphin",
                        lambda p=path, u=url: self.launch(
                            ["dolphin", p], u)),
                    Action("code", "Open in VS Code",
                        lambda p=path, u=url: self.launch(
                            ["code", p], u)),
                ]))

    def launch(self, cmd, url):
        subprocess.Popen(cmd)
        db = sqlite3.connect(os.path.expanduser("~/.local/share/repo-index.db"))
        db.execute("""UPDATE repos SET open_count = open_count + 1,
            last_opened = datetime('now') WHERE remote_url = ?""", (url,))
        db.commit()
```

Trigger becomes `r <query>` in Albert. The frecency ordering is in the SQL. Actions are keyboard-navigable via Albert's standard UI.

### Option 3: KRunner runner (don't — yet)

For system-wide "type anywhere, no trigger word needed" it would be the most polished result. But per-result Alt-key actions are awkward in KRunner and the Plasma 6 Python runner template story is still shaky (flagged in the earlier launcher output). Revisit if Albert isn't enough.

## The index behind both options

Both options read from a single `~/.local/share/repo-index.db`:

```sql
CREATE TABLE repos (
  remote_url TEXT PRIMARY KEY,   -- stable identity
  name TEXT NOT NULL,
  owner TEXT,
  description TEXT,
  topics TEXT,
  local_path TEXT,               -- NULL if uncloned
  open_count INTEGER DEFAULT 0,
  last_opened TEXT
);
```

Populated by a ~50-line Python script on a cron:

- `gh repo list danielrosehill --limit 1000 --json ...` → upsert metadata.
- `fd -t d -H '^\.git$' ~/repos/github/` + `git -C <parent> remote get-url origin` → fill `local_path` by matching on remote URL.
- This is the **same DB** as the fleet-manager launcher design (earlier output). One index, multiple front ends.

## Recommended sequence

1. **Today (15 min):** build the SQLite index + Rofi script. Bind `Meta+R`. Ship it.
2. **Next weekend:** write the Albert extension reading the same DB. Keep both working so you can compare.
3. **Later:** add uncloned-repos to search results with a "Clone into `~/repos/github/_inbox/` then open" action, so the runner becomes a unified find-and-open for every repo you own, not just cloned ones.

## Composes with other outputs

- Index → shared with the search-first launcher design.
- `local_path` updates → driven by the `systemd.path` watcher from the auto-symlink output.
- Remote-URL identity → matches GRM's clone-set sync model; filesystem reorganisation never breaks the runner.
- Frecency column → travels between machines if `~/.local/share/repo-index.db` is synced via Syncthing, giving you the same MRU ordering on laptop and desktop.

## Open Questions

- Should Rofi also show an inline indicator for dirty repos (uncommitted changes)? Cheap: add a `status` column refreshed by the same cron.
- Is Rofi on Wayland (KDE Plasma 6) actually working well now, or is `rofi-wayland` / `wofi` needed? Verify before committing.
- Does Albert 2.x run cleanly on Plasma 6 Wayland? Worth a quick test before investing in the extension.

## Sources

- [Rofi custom keybindings](https://github.com/davatorium/rofi/blob/next/doc/rofi.1.markdown) — `-kb-custom-N`
- [Albert launcher Python extensions](https://albertlauncher.github.io/reference/python/)
- [sesh](https://github.com/joshmedeski/sesh)
- [zoxide](https://github.com/ajeetdsouza/zoxide)
- [rofi-wayland](https://github.com/lbonn/rofi)
- [KWin custom shortcuts](https://userbase.kde.org/Plasma/Shortcuts)
