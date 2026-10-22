-- Rex configuration.
--
-- Keymap migrated from ~/.config/herdr/config.toml, ~/.config/tmux/tmux.conf,
-- and Kitty's project jumps. KEYMAPS.md is the reference: every shortcut, the
-- resize mode, the project sessions, and what has no Rex client equivalent.
-- Ctrl+A is the prefix, as in every source. Run `rex config reload` after
-- editing.
--
-- Session management and the project sessions live in sessions.lua; the fzf
-- manager lives in session_management.lua. Both are modules beside this file;
-- this file keeps the pane and tab shortcuts.
--
-- No Cmd shortcut or bare Ctrl+H/J/K/L is bound here, so the client's own
-- defaults stay reachable.

local PREFIX = "ctrl+a"

-- Pane focus and resize share these directions.
local DIRECTIONS = {
  { key = "h", direction = "left" },
  { key = "j", direction = "down" },
  { key = "k", direction = "up" },
  { key = "l", direction = "right" },
}

-- Resize mode is available through `rex do client.mode.enter name=resize`.
-- Exclusive, so typing cannot leak into a pane while resizing; Escape and
-- Enter leave it. Prefix+Shift+R is reserved for reload.
rex.mode("resize", { exclusive = true })
for _, entry in ipairs(DIRECTIONS) do
  rex.bind("resize/" .. entry.key, "pane.resize", { direction = entry.direction })
end
rex.bind("resize/left", "pane.resize", { direction = "left" })
rex.bind("resize/down", "pane.resize", { direction = "down" })
rex.bind("resize/up", "pane.resize", { direction = "up" })
rex.bind("resize/right", "pane.resize", { direction = "right" })
rex.bind("resize/esc", "client.mode.exit")
rex.bind("resize/enter", "client.mode.exit")

-- Reload, and send the prefix itself with a double press.
rex.bind(PREFIX .. ">shift+r", "client.config.reload")
rex.bind(PREFIX .. ">" .. PREFIX, "pane.send_key", { key = PREFIX })

-- Sessions (Herdr workspaces) and the project jumps live in sessions.lua, the
-- module beside this file. It receives the prefix declared above, so both files
-- share one prefix value; edit project tabs there and reload after either file.
require("sessions").setup(PREFIX)

-- The fzf session manager lives in session_management.lua. It browses the
-- presets above and manages running sessions, using the same prefix.
require("session_management").setup(PREFIX)

-- Tabs.
rex.bind(PREFIX .. ">c", "client.tab.new")
rex.bind(PREFIX .. ">shift+t", "client.tab.rename")
rex.bind(PREFIX .. ">p", "client.tab.previous")
rex.bind(PREFIX .. ">shift+x", "client.tab.close")
for index = 1, 9 do
  rex.bind(PREFIX .. ">" .. tostring(index), "client.tab.goto", { index = index })
end

-- Pane focus wraps at the edge, like tmux select-pane.
for _, entry in ipairs(DIRECTIONS) do
  rex.bind(PREFIX .. ">" .. entry.key, "pane.focus", {
    direction = entry.direction,
    wrap = true,
  })
end
rex.bind(PREFIX .. ">tab", "pane.focus_next")
rex.bind(PREFIX .. ">shift+tab", "pane.focus_previous")

-- Splits: v and minus in Herdr, % and " in tmux (written as the key without
-- shift applied). Split-down keeps only tmux's `"`, because prefix+- is a
-- project jump.
rex.bind(PREFIX .. ">v", "pane.split", { direction = "right" })
rex.bind(PREFIX .. ">shift+5", "pane.split", { direction = "right" })
rex.bind(PREFIX .. ">shift+'", "pane.split", { direction = "down" })

-- Close the focused pane first, then the tab (Rex falls back to the window).
rex.bind(PREFIX .. ">x", "client.close")
rex.bind(PREFIX .. ">z", "pane.zoom")
rex.bind(PREFIX .. ">b", "client.sidebar.toggle")

-- ? opened help in Herdr; the command palette is the closest Rex client
-- surface. Settings moved from prefix+s (now the project browser) to
-- prefix+Shift+S.
rex.bind(PREFIX .. ">shift+/", "client.palette.toggle")
rex.bind(PREFIX .. ">shift+s", "client.settings")
