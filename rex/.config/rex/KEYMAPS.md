# Rex keymap from Herdr, tmux, and Kitty

`~/.config/rex/init.lua` carries the keymap from `~/.config/herdr/config.toml`
and `~/.config/tmux/tmux.conf`, and it loads `~/.config/rex/sessions.lua` for
session management and Kitty's project jumps. Ctrl+A is the prefix,
with tmux-first defaults, overridden by Kitty's named-project keys and the
pane-first close shortcut. This config contains only keymaps and session management: no tmux-navigator integration, process
detection, or bare Ctrl+H/J/K/L bindings. Unsupported mappings are listed below.

## Files

| File | Holds |
| --- | --- |
| `init.lua` | Prefix, resize mode, reload, tab, pane, split, panel, and palette keys. It ends its session section with `require("sessions").setup(PREFIX)`. |
| `sessions.lua` | Session picker/new/rename/close keys, the project tab templates, the `jump_project` action, and its five project keys. |

`init.lua` passes the prefix to the module, so `PREFIX` stays declared in one
place. Project directories and tabs are defined only in `sessions.lua`; edit
them there, then reload after either file changes. Rex resolves `sessions.lua`
beside `init.lua`, so no other path setup is needed.

## Quick path

1. `stow --target=$HOME rex` to place `init.lua` and `sessions.lua` at
   `~/.config/rex/`.
2. `rex config reload` (or the command palette) to make the running server read them.
3. `rex config check ~/.config/rex/init.lua` to confirm both files load clean.

## Prefix keys (Ctrl+A)

Press Ctrl+A, release, then the key. Press Ctrl+A twice to send one Ctrl+A to
the focused program.

| Key | Action | From |
| --- | --- | --- |
| `Ctrl+A` | Send Ctrl+A to the pane | tmux `send-prefix` |
| `Shift+R` | Reload config | User override |
| `s`, `Ctrl+S`, `Ctrl+X` | Session picker | tmux session-manager, Herdr `workspace_picker` |
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

Only five project keys are bound: `q`, `w`, `,`, `n`, and `-`. The Kitty keys
they replaced keep their other homes: `w` no longer opens the session picker
(still on `s`, `Ctrl+S`, `Ctrl+X`), `n` no longer moves to the next tab (`p`
still goes to the previous tab), and `-` no longer splits down (still on `Shift+'`). `r` (reload, now
on `Shift+R`, the palette, and `rex config reload`) and `e` (Herdr's scrollback
editor, which had no client action) are now unbound.

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

The config still defines four more project templates that no key opens:
`centai`, `sergio`, `conectea-web`, and `conectea-jea`. They stay available for
`rex do jump_project project=<name>` (or after binding a key), with the same
directory and tab behavior as the bound ones. The templates and the action are
both in `sessions.lua`.

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
| tmux `bind -r C-k` (interactive kill picker) | no equivalent, so `Ctrl+K` stays unbound rather than closing the session |
| tmux copy mode (`bind -T copy-mode-vi v` / `y`) | no copy mode; use the terminal's own selection |
| tmux `bind -r` repeat | each Rex shortcut needs the prefix; there is no repeat-without-prefix |
| tmux session-manager `-s` / `-k` flags | flags unverified, so `s`, `Ctrl+S`, `Ctrl+X` open the native session picker and nothing serves `-k` |

## Where the sources disagreed

| Key | tmux | Herdr | Here |
| --- | --- | --- | --- |
| `r` | Reload | Resize mode | Unbound; reload is `Shift+R`, resize uses the mode action |
| `s` | Session picker | Settings | Session picker; settings moved to `Shift+S` |
| `?` | — | Help | Command palette |
| `e` | — | Scrollback editor (no client action) | Unbound; Herdr's editor had no client action |
| `w` | — | Workspace picker | Kitty jump to `sql-finaipro`; picker stays on `s`, `Ctrl+S`, `Ctrl+X` |
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
python3 rex/.config/rex/tests/test_keymaps.py   # keymaps and the project jump, via the rex CLI
rex config check ~/.config/rex/init.lua --json  # bindings, modes, actions, diagnostics
```

The tests use `rex config check` to load temporary copies of `init.lua` and the
`sessions.lua` beside it, with `rex.bindings()`/`rex.modes()` assertions
appended. They pin all 50 bindings,
session management, project jumps, resize mode, and the absence of navigator
actions or bare Ctrl+H interception. They also check that the native loader
finds `sessions.lua` from an unrelated working directory and reports it as
missing when absent. The project jump runs through
`rex do --action jump_project` against recording stubs, so no session is listed,
created, or selected; that part needs the local Rex server running to connect
to. Real app keystrokes are not automated; press a few after `rex config reload`.
