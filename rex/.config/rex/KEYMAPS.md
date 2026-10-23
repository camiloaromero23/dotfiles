# Rex keymap from Herdr, tmux, and Kitty

`~/.config/rex/init.lua` carries the keymap from `~/.config/herdr/config.toml`
and `~/.config/tmux/tmux.conf`, and it loads `~/.config/rex/sessions.lua` for
the project presets and `~/.config/rex/session_management.lua` for the fzf
session manager. Ctrl+A is the prefix, with tmux-first defaults, overridden by
Kitty's named-project keys, the fzf manager, and the pane-first close shortcut.
This config contains only keymaps and session management: no tmux-navigator
integration, process detection, or bare Ctrl+H/J/K/L bindings. Unsupported
mappings are listed below.

## Files

| File | Holds |
| --- | --- |
| `init.lua` | Prefix, resize mode, reload, tab, pane, split, panel, and palette keys. It ends its session section with `require("sessions").setup(PREFIX)` and `require("session_management").setup(PREFIX)`. |
| `sessions.lua` | Native session picker (`Ctrl+X`), new/rename/close keys, the project tab templates, the `jump_project` and `list_projects` actions, and the five project keys. |
| `session_management.lua` | The `session_manager` action and the `s` / `Ctrl+S` / `Ctrl+K` bindings. It opens a temporary floating terminal and returns its layer and block IDs. |
| `session_picker.lua` | The interactive fzf menus, run locally by `rex do` inside the popup. Uses native Rex Lua calls for projects, session selection and confirmed closing. |

`init.lua` passes the prefix to both modules, so `PREFIX` stays declared in
one place. Project directories and tabs are defined only in `sessions.lua`;
edit them there, then reload after either Lua file changes. Rex resolves both
modules beside `init.lua`, and the action finds the helper in that same
directory, so no other path setup is needed. Helper edits apply on the next
menu launch and need no reload. After adding the new helper, restow the Rex
package if your deployment uses individual file links rather than a directory link.

## Quick path

1. `stow --target=$HOME rex` to place `init.lua`, `sessions.lua`,
   `session_management.lua`, and `session_picker.lua` at `~/.config/rex/`.
2. `rex config reload` (or the command palette) to make the running server read the Lua files.
3. `rex config check ~/.config/rex/init.lua` to confirm every file loads clean.

## Prefix keys (Ctrl+A)

Press Ctrl+A, release, then the key. Press Ctrl+A twice to send one Ctrl+A to
the focused program.

| Key | Action | From |
| --- | --- | --- |
| `Ctrl+A` | Send Ctrl+A to the pane | tmux `send-prefix` |
| `Shift+R` | Reload config | User override |
| `s` | fzf project browser | Kitty project menu, tmux session picker |
| `Ctrl+S` | fzf running-session switcher by ID | tmux session-manager |
| `Ctrl+K` | fzf close with an explicit confirmation | tmux session-manager `-k` |
| `Ctrl+X` | Native Rex session picker | tmux session-manager |
| `Shift+N` / `Shift+W` / `Shift+D` | New / rename / close session | Herdr workspace actions |
| `q` `w` `,` `n` `-` | Jump to a named project | Kitty `keymaps.conf` |
| `c` / `Shift+T` / `Shift+X` | New / rename / close tab | Herdr tab actions |
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

Only five project keys are bound: `q`, `w`, `,`, `n`, and `-`. The manager's
`s` menu reaches the other four presets, while `Ctrl+S` and `Ctrl+K` handle
running sessions. The Kitty keys they replaced keep their other homes: `w` no
longer opens the session picker (now `Ctrl+X`), `n` no longer moves to the next
tab (`p` still goes to the previous tab), and `-` no longer splits down (still
on `Shift+'`). `r` (reload, now on `Shift+R`, the palette, and `rex config
reload`) and `e` (Herdr's scrollback editor, which had no client action) are now
unbound.

`x` uses Rex’s native `client.close`: focused pane, otherwise selected tab,
otherwise the app window if neither exists. `Shift+X` closes the whole tab directly.

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

| Key | Session | Tabs that start | Directory |
| --- | --- | --- | --- |
| `q` | `finaipro` | `nvim`, `server` = `bun run dev:local`, `pi` | `~/documents/work/finaipro/Web-Finaipro` |
| `w` | `sql-finaipro` | `nvim` | `~/Documents/work/finaipro/SQLDB-parameters-FinAIPro` |
| `,` | `dotfiles` | `nvim`, `shell` | `~/dotfiles` |
| `n` | `nvim` | `nvim`, `shell` | `~/.config/nvim` |
| `-` | `notes` | `nvim`, `nvim` | `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/notes` and `/Users/camilo/Library/CloudStorage/OneDrive-FINAIPROTECHNOLOGIESSAS/Finaipro Web Wiki` |

The config still defines four more project templates that no direct key opens:
`centai`, `sergio`, `conectea-web`, and `conectea-jea`. The manager's `s` menu
lists all nine presets, and `rex do jump_project project=<name>` still works
(or bind another key). They keep the same directory and tab behavior as the
bound ones. The templates and both project actions are in `sessions.lua`.

Every project tab uses `/opt/homebrew/bin/fish --login --interactive`,
including plain shell tabs and the untitled second `dotfiles` tab. The absolute
path avoids Rex.app's restricted PATH, which does not include Homebrew's bin
directory. A leading `~/` expands with `HOME`; paths with spaces stay literal.

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
| Kitty dependency | None at runtime. The tabs live in `sessions.lua`; Kitty's session files are never read. |
| Failures | An unknown project, a failed session list, or a failed create reports an error and selects nothing. |
| Activation | Reload the config (palette or `rex config reload`) after editing `init.lua` or `sessions.lua`; a newly started client picks them up on its own. |
| Missing key | Kitty's `ctrl+a>p` went to the previous session; `p` stays the previous tab here. |

## Session manager (fzf)

`session_management.lua` opens a temporary floating terminal in the current
session. That terminal runs `rex do session_picker.lua`, which uses Rex's
embedded Lua runtime and fzf. The launcher explicitly sets `REX_CLIENT` to the
invoking client; the helper inherits `REX_SERVER` and refuses missing context.
Native Lua tables replace JSON pipelines and `jq`; native calls handle the
project actions, session listing, client selection and exact-ID destruction.
No Bash helper, standalone Lua installation, tmux navigator or global shortcut
is added. fzf remains an external program.

| Key | Menu | What it does |
| --- | --- | --- |
| `s` | Projects | Lists all nine configured project names, sorted. Choosing one runs `jump_project`, which reuses the session with that exact label or creates it from the template and focuses its first tab. |
| `Ctrl+S` | Active sessions | Lists running sessions with the full ID hidden in each row. Choosing a row selects that ID in the invoking client. |
| `Ctrl+K` | Close session | Lists running sessions, then asks `Close session LABEL (ID)? [y/N]`. Only the exact answer `y` attaches this script to the selected ID and calls `session.destroy` for that same ID. |
| `Ctrl+X` | Native picker | Unchanged Rex session picker. |

**Presentation (Kitty-style)**

All three pickers use Kitty's `> ` prompt, rounded titled border,
`--no-multi` and `--no-clear`, with fzf's default layout and information line.
The border titles are `rex-session-manager`,
`rex-session-manager (active-sessions)` and
`rex-session-manager (kill-session)`. Session IDs stay hidden in the first
column; only the display label is shown.

The visible panel remains a genuine centered floating terminal, about 70% of
the Rex window's width and 60% of its height; underlying panes stay visible.
Current Rex Beta clips an offset layer before its nominal right/bottom edges,
so `BOUNDS` uses the compensated `{0.15, 0.20, 0.85, 0.80}` rectangle. A plain
120×20 corner-marker grid in its 146×27 terminal was visually confirmed to fit
and look correctly centered. The public API still documents `[x,y,w,h]`; this
is a workaround for the observed client rendering, not a different API contract.

fzf uses `--no-height --margin=0,18%,26%,0 --padding=0` to reserve the hidden
right/bottom bands. At the confirmed dimensions its rounded border occupies
that same 120×20 area. Keep the bounds and margins together, and recheck the
GUI after Rex renderer updates or window/font changes: percentage margins round
to terminal cells. These flags override inherited geometry; color preferences
are unchanged. There are no manual TTY-size queries, `stty` writes, size retries,
or background watchers; Rex remains the only owner of terminal sizing.

**Colors**

When Rex starts without fish's exported fzf settings, the helper supplies the
same Catppuccin Mocha palette: solid `#1E1E2E` background, `#CDD6F4` text,
colored highlights and border. An explicit `FZF_DEFAULT_OPTS` or
`FZF_DEFAULT_OPTS_FILE` takes precedence; the fallback does not replace either.
No fish initialization is needed to style the floating picker.

**Cancel and confirmation**

- `Esc` or no match in fzf closes the menu without creating, selecting, or closing anything.
- In the close confirmation, empty input, `Esc`, `Y`, `yes`, or any other answer keeps the session. The default is keep.
- An empty project list or an empty session list is also a no-op.
- A successful or cancelled menu exits 0 and closes the floating terminal. Rex owns the popup lifecycle: its fast-exit policy can close a nonzero exit before a later error is read. The launcher passes `interactive=true`, so the helper prints `Press Enter to close.` and waits on a nonzero exit. Direct script callers omit that argument for noninteractive use; they keep the error status without waiting. Session actions are never retried, polled, or replaced with fallback actions.

**Selection safety**

- Rows are data, never code. Project names and labels are passed as CLI arguments and are never evaluated or interpolated into a shell command.
- Session rows keep the full ID in a hidden first field and show the label in the second. Control characters are sanitized for display. Duplicate labels remain separately selectable and gain the full native session ID in brackets, such as `dotfiles [session:01a15ebd-b25a-735b-111111]`.
- The chosen row must exactly match one generated from the current listing. A label cannot substitute for an ID. If a selected session disappears, selection or attachment/destruction fails for that ID; nothing falls back to another session.
- Closing targets only the selected ID. The confirmation never defaults to close, and multi-selection is disabled.

**Files, dependencies, and failures**

| Topic | Decision |
| --- | --- |
| Helper location | `session_picker.lua` beside the loaded `init.lua`. The action gets that absolute directory from `client.keymap`, so copied configs and paths with spaces work. |
| Executables | `rex` from the server-provided PATH runs the Lua helper; fzf defaults to `/opt/homebrew/bin/fzf` and can be overridden with `FZF_BIN`. No `jq`, Bash helper or separate Lua runtime is required. |
| Server and client | The launcher uses `--autostart=false`, the inherited `REX_SERVER`, and an explicitly pinned `REX_CLIENT`. `rex.invoke` and `rex.client.queue` use that bound context, never a guessed client. Only fzf's child environment clears `REX_CLIENT`. |
| Missing input | A missing `REX_SERVER`, client ID, helper, or executable reports an error and stops before any selection, switch, or close. A local script run has no client ID, so the action refuses instead of guessing one. |
| Backend errors | A failed project action, session listing, selection, attachment or destruction reports the native error and exits 3. Local failures exit 1, bad arguments exit 2, and fzf failures preserve its exit status. Cancellation is distinct from a successful but empty selection. |

Local failures print `Error: …` on stderr and exit 1, or exit 2 for bad
arguments. Examples:

- `REX_SERVER is not set; run this manager from a Rex terminal`
- `session_manager needs the invoking client; run it from a Rex shortcut or pass -C`
- `session manager helper is missing or unreadable: <path>`
- `fzf is not executable: <path>`
- `REX_CLIENT is not set; run this picker from a Rex shortcut`
- `fzf returned an empty selection`
- `the selection is not one of the listed projects` (or `sessions`)

The Lua helper reports native backend errors without fallback actions and uses
exit 3, matching the Rex CLI's backend-error status. The popup launcher enables
error acknowledgement with `interactive=true`; direct callers leave it off:

```bash
REX_CLIENT=<invoking-client-id> rex --autostart=false do ./session_picker.lua mode=active
```

Run this from a Rex terminal so `REX_SERVER` is inherited. The script accepts
`mode=projects`, `mode=active`, or `mode=close`. Error acknowledgement does not
change the failure status. Rex's native fast-exit policy remains unchanged.

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
| `s` | Session picker | Settings | fzf project browser; `Ctrl+S` switches sessions, `Ctrl+K` closes one, `Ctrl+X` keeps the native picker, and settings moved to `Shift+S` |
| `Ctrl+K` | Interactive kill picker | — | fzf close after an explicit `y` confirmation |
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
rex config check rex/.config/rex/init.lua --json  # bindings, modes, actions, diagnostics
rex do -e 'assert(loadfile("rex/.config/rex/session_picker.lua"))' # syntax only; does not run the picker
```

The automated regression tests were removed by request. These checks validate
configuration loading and shell syntax; they do not provide behavioral coverage.

For a visual check, close the picker, reload with `Ctrl+A` then `Shift+R`, and
reopen it. Check cancellation against disposable sessions; only test confirmed
closing on a disposable session, because it terminates running programs.
