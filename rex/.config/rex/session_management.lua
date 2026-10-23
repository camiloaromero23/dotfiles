-- Session manager menus for the Rex config beside this file.
--
-- `sessions.lua` owns the project presets and the `jump_project` action. This
-- module only browses them and manages running sessions. Each menu opens a
-- temporary floating terminal that runs `session_picker.lua` with Rex's Lua
-- runtime and fzf. Native calls use the inherited REX_SERVER and the pinned
-- invoking client. Escape cancels without creating, selecting,
-- or closing anything, and closing asks for an explicit confirmation.
--
-- `init.lua` keeps the prefix and calls `require("session_management").setup(PREFIX)`.

local SHELL_FLAVOR = "com.superlogical.terminal.shell"
local HELPER = "session_picker.lua"

-- A floating layer in the moments after the key press. The helper closes the
-- layer itself by exiting with status 0 through the terminal's exit option.
-- Rex owns the popup lifecycle and may close a quick failure before a later
-- error is read; on a real terminal the helper waits for Enter on a nonzero
-- exit so the message stays readable. Native fast-exit timing is unchanged.
-- Current Rex Beta clips offset layers before their nominal right/bottom edges.
-- These compensated bounds display a centered 70% x 60% panel. Its terminal is
-- larger than the visible area; keep session_picker.lua's margins in sync.
local BOUNDS = { 0.15, 0.20, 0.85, 0.80 }

local MODES = {
  projects = true,
  active = true,
  close = true,
}

local ARGS = {
  type = "object",
  properties = {
    mode = {
      type = "string",
      enum = { "projects", "active", "close" },
    },
  },
  required = { "mode" },
  additionalProperties = false,
}

-- The loaded init.lua path from client.keymap. The helper sits beside it, so a
-- copied config or a path with spaces needs no extra setup.
local function config_directory(path)
  local directory = path:match("^(.*)/[^/]*$")
  if directory == nil or directory == "" then
    return nil
  end
  return directory
end

local function require_helper(directory)
  local helper = directory .. "/" .. HELPER
  local file = io.open(helper, "r")
  if file == nil then
    error("session manager helper is missing or unreadable: " .. helper, 0)
  end
  file:close()
  return helper
end

local function session_manager(ctx, args)
  local mode = args.mode
  if not MODES[mode] then
    error("unknown session manager mode: " .. tostring(mode), 0)
  end

  -- A local script action has no client, and guessing one could act on another
  -- app or server. Refuse before opening a picker.
  if ctx.client_id == nil or ctx.client_id == "" then
    error(
      "session_manager needs the invoking client; run it from a Rex shortcut or pass -C",
      0
    )
  end
  if ctx.session_id == nil or ctx.session_id == "" then
    error("session_manager needs the invoking session", 0)
  end

  local keymap, keymap_error = rex.call("client.keymap", {})
  if keymap == nil then
    error("client.keymap failed: " .. tostring(keymap_error), 0)
  end
  local config = keymap.config
  if type(config) ~= "table" or type(config.path) ~= "string" or config.path == "" then
    error("client.keymap returned no configuration path", 0)
  end
  local directory = config_directory(config.path)
  if directory == nil then
    error("client.keymap returned an unusable configuration path: " .. config.path, 0)
  end
  local helper = require_helper(directory)

  local layer, layer_error = rex.session.new_layer({
    session_id = ctx.session_id,
    bounds = BOUNDS,
    focus = true,
    layout = rex.layout.block{
      flavor = SHELL_FLAVOR,
      options = {
        shell = "none",
        command = {
          "/usr/bin/env", "REX_CLIENT=" .. ctx.client_id,
          "rex", "--autostart=false", "do", helper,
          "mode=" .. mode, "interactive=true",
        },
        exit = { on_completion = true },
      },
    },
  })
  if layer == nil then
    error("session.new_layer failed: " .. tostring(layer_error), 0)
  end

  return { layer_id = layer.layer_id, block_ids = layer.block_ids }
end

local M = {}

-- Register the `session_manager` action and its three keys. Call once, with
-- the prefix declared by init.lua.
function M.setup(PREFIX)
  rex.action{
    name = "session_manager",
    title = "Session Manager",
    description = "Browse projects, switch running sessions by ID, or close one after confirmation.",
    category = "Sessions",
    keywords = "fzf projects active close",
    args = ARGS,
    run = session_manager,
  }

  -- Prefix+s browses every project preset; Prefix+Ctrl+S switches to a running
  -- session; Prefix+Ctrl+K closes one only after confirmation. The native Rex
  -- picker stays on Prefix+Ctrl+X.
  rex.bind(PREFIX .. ">s", "session_manager", { mode = "projects" })
  rex.bind(PREFIX .. ">ctrl+s", "session_manager", { mode = "active" })
  rex.bind(PREFIX .. ">ctrl+k", "session_manager", { mode = "close" })
end

return M
