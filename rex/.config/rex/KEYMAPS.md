# Rex keymap from Herdr, tmux, and Kitty

`~/.config/rex/init.lua` carries the keymap from `~/.config/herdr/config.toml`
and `~/.config/tmux/tmux.conf`, and it loads `~/.config/rex/sessions.lua`, which
reads the project presets from `~/.config/rex/sessions/*.json`, and
`~/.config/rex/session_management.lua` for the session manager. Ctrl+A is the prefix, with tmux-first defaults, overridden by
Kitty's named-project keys, the session manager, and the pane-first close shortcut.
This config contains only keymaps and session management: no tmux-navigator
integration, process detection, or bare Ctrl+H/J/K/L bindings. Unsupported
mappings are listed below.

## Files

| File | Holds |
| --- | --- |
| `init.lua` | Prefix, resize mode, reload, tab, pane, split, panel, and palette keys. It ends its session section with `require("sessions").setup(PREFIX)` and `require("session_management").setup(PREFIX)`. |
| `sessions.lua` | Reads and validates the project presets from `sessions/` on every `list_projects` and `jump_project` call, and holds the native session picker (`Ctrl+X`), the new/rename/close keys, the two project actions, and the project keys. |
| `sessions/` | One JSON file per project preset: `{"name": ..., "tabs": [{"cwd": ..., "run": ...}]}`. `name` is what the keys and `jump_project` use, so it is unique across files; the file name is only for humans. |
| `session_management.lua` | The `session_manager` action and the `s` / `Ctrl+S` / `Ctrl+K` bindings. It asks with `rex.ui.pick` and acts on the answer. |

`init.lua` passes the prefix to both modules, so `PREFIX` stays declared in
one place. Project directories and tabs are defined only in `sessions/`, and the
directory is read on every menu open and every jump: create, edit, or delete a
`*.json` file there and the change is live immediately, with **no `rex config
reload`** and no Lua edit. A reload is only for a change to a Lua file. The
extension match ignores case (`FINAIPRO.JSON` loads), and hidden files and
non-JSON entries (`README.md`, `.DS_Store`) are ignored. A broken preset is
never used silently: opening the menu or running a jump fails with an error
naming the file. Unparseable JSON, a
missing or empty `name`, an unknown key such as `command` instead of `run`, a
duplicate `name`, an empty `tabs` array, or a missing `cwd` all fail that way,
while the rest of the config still loads. Rex resolves both modules beside
`init.lua`, and the action finds the helper in that same
directory, so no other path setup is needed. Helper edits apply on the next
menu launch and need no reload. After adding the new helper, restow the Rex
package if your deployment uses individual file links rather than a directory link.

## Quick path

1. `stow --target=$HOME rex` to place `init.lua`, `sessions.lua`,
   `session_management.lua`, and the `sessions/` directory at `~/.config/rex/`.
2. `rex config reload` (or the command palette) to make the running server read the Lua files.
3. `rex config check ~/.config/rex/init.lua` to confirm the Lua files load clean,
   and `rex do list_projects` to list the presets currently on disk.

## Prefix keys (Ctrl+A)

Press Ctrl+A, release, then the key. Press Ctrl+A twice to send one Ctrl+A to
the focused program.

| Key | Action | From |
| --- | --- | --- |
| `Ctrl+A` | Send Ctrl+A to the pane | tmux `send-prefix` |
| `Shift+R` | Reload config | User override |
| `s` | Project preset picker | Kitty project menu, tmux session picker |
| `Ctrl+S` | Running-session switcher by ID | tmux session-manager |
| `Ctrl+K` | Close a session, no confirmation | tmux session-manager `-k` |
| `Ctrl+X` | Native Rex session picker | tmux session-manager |
| `Shift+N` / `Shift+W` / `Shift+D` | New / rename / close session | Herdr workspace actions |
| `q` `w` `,` `n` `-` | Jump to a named project | Kitty `keymaps.conf` |
| `c` / `Shift+X` | New / close tab | Herdr tab actions |
| `p` | Previous tab | Herdr `previous_tab` |
| `1`…`9` | Go to tab 1…9 | Herdr `switch_tab` |
| `h` `j` `k` `l` | Focus pane left / down / up / right | Herdr `focus_pane_*`, tmux `select-pane` |
| `Tab` / `Shift+Tab` | Next / previous pane | Herdr `cycle_pane_*` |
| `v`, `Shift+5` (`%`) | Split right | Herdr `split_vertical`, tmux `%` |
| `Shift+'` (`"`) | Split down | tmux `"` |
| `x` | Close focused pane first, otherwise selected tab | User override |
| `z` | Zoom pane | Herdr `zoom` |
| `b` | Toggle sidebar | Herdr `toggle_sidebar` |
| `Shift+/` (`?`) | Command palette | Herdr `help` (closest client action) |
| `Shift+S` | Settings | Herdr `settings` (moved) |

Only three project keys are bound: `,`, `n`, and `-`. `q` and `w` stay commented
out in `sessions.lua` because `finaipro` and `sql-finaipro` are no longer presets;
uncomment a line after restoring its JSON file. The manager's
`s` menu reaches every preset regardless of keys, while `Ctrl+S` and `Ctrl+K` handle
running sessions. The Kitty keys they replaced keep their other homes: `w` no
longer opens the session picker (now `Ctrl+X`), `n` no longer moves to the next
tab (`p` still goes to the previous tab), and `-` no longer splits down (still
on `Shift+'`). `r` (reload, now on `Shift+R`, the palette, and `rex config
reload`) and `e` (Herdr's scrollback editor, which had no client action) are now
unbound.

`x` uses Rex’s native `client.close`: focused pane, otherwise selected tab,
otherwise the app window if neither exists. `Shift+X` closes the whole tab directly.

This config never names a tab. `Shift+T` (`client.tab.rename`) is not bound, and
`sessions.lua` creates no window with a `window_label`. Rex titles each tab from
the program running in it, following `Workspace.prefersGeneratedTitles` in
`preferences.plist`. Renaming is still reachable from the app's own UI, but no
keymap or preset here sets a title.

Pane focus wraps at the edge, the way tmux `select-pane` does: with two panes,
`prefix h` from the left pane lands on the right one.

Keys are written the Rex way, without shift applied, so `%` is `shift+5` and
`"` is `shift+'`. Herdr's `minus` spelling is not a Rex key name; the literal
`-` is a project jump, and split-down keeps tmux's `"`.

## Project jumps

Each project key opens the Rex session whose label is exactly the project name.
An existing session is only switched to, preserving its current tab, programs,
and state. A missing session is created from the tabs below in one
all-or-nothing call, then opened on its first tab. A creation failure leaves
no partial session or window behind.

| Key | Session | Tabs (program each runs) | Directory |
| --- | --- | --- | --- |
| `,` | `dotfiles` | `nvim`, plain shell | `~/dotfiles` |
| `n` | `nvim` | `nvim`, plain shell | `~/.config/nvim` |
| `-` | `notes` | `nvim`, `nvim` | `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/notes` and `/Users/camilo/Library/CloudStorage/OneDrive-FINAIPROTECHNOLOGIESSAS/Finaipro Web Wiki` |

`q` (`finaipro`) and `w` (`sql-finaipro`) are commented out in `sessions.lua`
until those presets come back. The `sessions/` directory holds every preset,
including ones no key opens, such as `ansible`: the manager's `s` menu lists all
of them, and `rex do jump_project project=<name>` works for any of them (or bind
another key), with the same directory and tab behavior as the bound ones. The
presets are the JSON files in `sessions/`; both project actions are in
`sessions.lua`.

Every project tab uses `/opt/homebrew/bin/fish --login --interactive`,
including plain shell tabs. No tab carries a title: Rex names each one from its
foreground program. The absolute path avoids Rex.app's restricted PATH, which
does not include Homebrew's bin directory. A leading `~/` expands with `HOME`;
paths with spaces stay literal.

A program tab does not run its command through `fish -c`. Instead it passes the
command as the tab's startup input: Rex types `'<command>\n'` into the
interactive fish once it starts. The program runs in the foreground, so the
terminal reports it as the foreground process, and the original interactive
shell returns when it exits. Foreground-process reporting for this launch was
confirmed with an isolated Rex server; whether the GUI then renders the
program's own icon is not verified here. Nothing waits for a startup-complete
or readiness signal; the text is sent exactly as given. Plain shell tabs get no startup
input. This applies only to sessions created from the template; an existing
session is switched to and keeps its running tabs.

| Behavior | Decision |
| --- | --- |
| Match | Case-sensitive, exact session label. Rex does not enforce unique labels, so if two sessions share one, the jump fails with an error instead of choosing one. Rename or close the extra session first. Two presses before the first create lands can produce such a pair. |
| Kitty dependency | None at runtime. The tabs live in `sessions/*.json`; Kitty's session files are never read. |
| Failures | An unknown project, a failed session list, or a failed create reports an error and selects nothing. |
| Activation | Reload the config (palette or `rex config reload`) after editing `init.lua` or `sessions.lua`; a newly started client picks them up on its own. A preset in `sessions/` needs no reload. |
| Missing key | Kitty's `ctrl+a>p` went to the previous session; `p` stays the previous tab here. |

## Session manager (`rex.ui.pick`)

`session_management.lua` registers one `session_manager` action that asks in the
command palette with the native `rex.ui.pick` prompt. Rex draws the list in the
invoking app: there is no popup terminal, no helper script, no `client.keymap`
round trip, and no external picker. It needs a Rex build that ships prompts.

| Key | Menu | What it does |
| --- | --- | --- |
| `s` | Projects | Lists every project preset name, sorted. Choosing one runs `jump_project`, which reuses the session with that exact label or creates it from the template and focuses its first tab. |
| `Ctrl+S` | Active sessions | Lists running sessions. Choosing a row selects that ID in the invoking client. |
| `Ctrl+K` | Close session | Lists running sessions and closes the chosen row at once. The committing row is labelled `Close session`; there is no second confirmation. It attaches this connection to the selected ID and calls `session.destroy` for that same ID. |
| `Ctrl+X` | Native picker | Unchanged Rex session picker. |

**Why the code is shaped this way**

`rex.ui.pick` only asks from an action's `run` function and the functions it
calls directly. Elsewhere it returns `nil, "failed"` and logs a warning instead
of asking, which is easy to mistake for a cancel.

| Constraint | Consequence here |
| --- | --- |
| Only on the action's own call stack | The keys bind the action's name. A `rex.bind(key, function() … end)` closure could never show the menu. |
| Not through `pcall`/`xpcall` | `ask` is never wrapped; a prompt failure propagates instead of turning into a silent `failed`. |
| Not through `rex.invoke` | `jump_project` runs after the answer is known, so it never needs to ask. |
| Not from `rex.on` handlers, the config top level, or library callbacks | Nothing here asks from those places. |

**Presentation**

Rex draws the prompt: title `Select Session`, `Active Sessions 🟢`, or
`Kill Session 💀`; a filter field with no placeholder; the `code` icon on
every row of every menu (`ROW_ICON`, one value for all three); and a committing
row labelled `Open Session`, `Switch Session`, or `Close Session`. Selection is
single: `multiple` and `allow_other` are off.

**Prompts reach every connected app**

A palette prompt is shown by every Rex app connected to the server, including on
other devices; the first answer wins and the prompt closes everywhere else.
Cancelling on any one of them cancels it. Keep that in mind for `Ctrl+K`, which
is destructive on the answer it receives.

**Cancel and failures**

- `Esc` closes the menu without creating, selecting, or closing anything.
- An empty project list or an empty session list opens no prompt at all.
- Choosing a row in the close menu destroys that session immediately. There is no confirmation prompt, so `Ctrl+K` is destructive on whichever row you accept.
- Any other outcome — `timeout`, `no_client`, `unsupported`, `busy`, `failed` — raises an error naming the reason and acts on nothing. `unsupported` means the connected app is older than the server, which needs control API revision 17 for prompts.
- Session actions are never retried, polled, or replaced with fallback actions.

**Selection safety**

- Rows are data, never code. Project names and session IDs are passed to native Rex calls and are never evaluated or interpolated into a shell command.
- Each row's `id` is the exact thing acted on: the preset name for projects, the full native session ID for sessions. A label cannot substitute for an ID.
- Control characters in a label are replaced with `?` for display. A repeated label keeps its bare title and gains the full session ID as a subtitle, so duplicates stay separately selectable.
- If a selected session disappears, selection or attachment/destruction fails for that ID; nothing falls back to another session.
- One accepted row is exactly one session: single selection, no multi-select.

**Files and dependencies**

| Topic | Decision |
| --- | --- |
| Helper | None. The action, the menus, and the failure handling all live in `session_management.lua`. |
| Executables | None beyond Rex itself. No fzf, no `jq`, no Bash helper, no standalone Lua installation, no `REX_CLIENT`/`REX_SERVER` plumbing. |
| Client | The invoking client is required; the prompt and `rex.client.queue` both go through it, so the action refuses instead of guessing one. |
| Client actions | Showing a session in the app is a client action, so Rex.app must accept actions: turn on Remote Control in its Settings, under Rex Server. With it off, the server answers `client.perform` with status 403 and the selection reports `Rex.app is not accepting actions`. |
| Backend errors | A failed project action, session listing, selection, attachment or destruction raises the native error. Nothing is retried. |

Messages raised by this action:

- `session_manager needs the invoking client; run it from a Rex shortcut or pass -C`
- `unknown session manager mode: <mode>`
- `session_manager could not show the <mode> menu: <reason>` with the detail appended after `—` when Rex supplies one

## Resize mode

Enter with `rex do client.mode.enter name=resize`; there is no dedicated
shortcut because `Ctrl+A Shift+R` reloads the config. The mode is exclusive,
so ordinary keystrokes do not reach the terminal while resizing.

| Key | Effect |
| --- | --- |
| `h` / `Left`, `l` / `Right` | Resize left, right |
| `j` / `Down`, `k` / `Up` | Resize down, up |
| `Esc` / `Enter` | Leave resize mode |

Each step moves the divider by Rex's default 5 percent. Esc also leaves any Rex
mode on its own.

## No Rex client equivalent

These source actions are not ported: the installed client's action list has
no matching action. Their original keys may serve a project jump instead;
for example, `q` opens `finaipro` rather than detaching.

| Source binding | Installed client actions |
| --- | --- |
| Herdr new/open/remove worktree (`prefix+Shift+G`, …) | no worktree action |
| Herdr `goto = prefix+g` | no goto picker; use `1`…`9` or the palette |
| Herdr `rename_pane = prefix+Shift+P` | no rename-pane action |
| Herdr `open_notification_target = prefix+o` | no notification action |
| Herdr agent navigation (`previous_agent`, `next_agent`, `focus_agent`) | no agent navigation action |
| Herdr `detach = prefix+q` | no detach action; quitting the app is the equivalent |
| tmux copy mode (`bind -T copy-mode-vi v` / `y`) | no copy mode; use the terminal's own selection |
| tmux `bind -r` repeat | each Rex shortcut needs the prefix; there is no repeat-without-prefix |

## Where the sources disagreed

| Key | tmux | Herdr | Here |
| --- | --- | --- | --- |
| `r` | Reload | Resize mode | Unbound; reload is `Shift+R`, resize uses the mode action |
| `s` | Session picker | Settings | Project preset picker; `Ctrl+S` switches sessions, `Ctrl+K` closes one, `Ctrl+X` keeps the native picker, and settings moved to `Shift+S` |
| `Ctrl+K` | Interactive kill picker | — | Close with no confirmation prompt |
| `?` | — | Help | Command palette |
| `e` | — | Scrollback editor (no client action) | Unbound; Herdr's editor had no client action |
| `w` | — | Workspace picker | Kitty jump to `sql-finaipro`; session menus stay on `Ctrl+S`, `Ctrl+K`, `Ctrl+X` |
| `n`, `-` | — | Next tab, split down | Kitty jumps to `nvim` and `notes`; split down stays on `Shift+'` |

## Notes

- Rex resolves the client's defaults, then this file, then shortcuts saved in
  the app itself. A shortcut saved with **Change Shortcut…** wins over this
  file.
- No Cmd shortcut and no bare Ctrl+H, Ctrl+J, Ctrl+K, or Ctrl+L is bound here.
- A key that starts a sequence no longer reaches the terminal, which is why the
  prefix passthrough exists.

## Verifying

```bash
rex config check rex/.config/rex/init.lua --json   # bindings, modes, actions, diagnostics
```

The automated regression tests were removed by request. This check validates
configuration loading only; it does not provide behavioral coverage.

For a visual check, close the picker, reload with `Ctrl+A` then `Shift+R`, and
reopen it. Check cancellation against disposable sessions; only test confirmed
closing on a disposable session, because it terminates running programs.
