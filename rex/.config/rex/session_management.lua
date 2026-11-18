-- Session manager menus for the Rex config beside this file.
--
-- The `rex-session-manager` binary builds each menu (through
-- `rex_session_manager.lua`) and performs the jump or the close; this module
-- only asks in the command palette with the native `rex.ui.pick` prompt and
-- dispatches the answer. Escape cancels without creating, selecting, closing,
-- saving, or deleting anything; closing destroys the chosen session at once.
-- Saving asks a second question before replacing an existing preset, and
-- deleting always asks one before removing a preset file.
--
-- `rex.ui.pick` only asks from inside an action's `run` function and the
-- functions it calls directly. A key-bound closure, a `pcall`/`xpcall` wrapper,
-- a handler registered with `rex.on`, or a function reached through
-- `rex.invoke` gets `nil, "failed"` instead of a prompt. Every path below stays
-- on this call stack for that reason; do not wrap the `ask` call in `pcall`,
-- and keep the keys bound to this action's name.
--
-- `init.lua` keeps the prefix and calls `require("session_management").setup(PREFIX)`.

local manager = require("rex_session_manager")

local MODES = { projects = true, active = true, close = true, save = true, delete = true }

local ARGS = {
  type = "object",
  properties = {
    mode = {
      type = "string",
      enum = { "projects", "active", "close", "save", "delete" },
    },
  },
  required = { "mode" },
  additionalProperties = false,
}

local function fail(message)
  error(message, 0)
end

-- The only call that asks the person. It must run on the action's own stack:
-- see the note at the top of this file before moving it behind an `invoke` or
-- a `pcall`. `menu` is the binary's `{title, confirm, items}`, passed as is.
local function ask(mode, menu)
  local id, why, detail = rex.ui.pick{
    title = menu.title,
    confirm = menu.confirm,
    items = menu.items,
  }
  if id ~= nil then
    return id
  end
  if why == "cancelled" then
    return nil
  end
  fail(
    "session_manager could not show the " .. mode .. " menu: "
      .. tostring(why or "unknown")
      .. (detail and (" — " .. detail) or "")
  )
end

local function session_manager(ctx, args)
  local mode = args.mode
  if not MODES[mode] then
    fail("unknown session manager mode: " .. tostring(mode))
  end

  -- The prompt is delivered through this client, and session.select acts on
  -- it. Guessing a client could act on another app.
  if ctx.client_id == nil or ctx.client_id == "" then
    fail("session_manager needs the invoking client; run it from a Rex shortcut or pass -C")
  end

  local menu = manager.run("menu", mode)
  if menu.items == nil or #menu.items == 0 then
    return {}
  end
  local choice = ask(mode, menu)
  if choice == nil then
    return {}
  end

  if mode == "projects" then
    manager.jump(choice)
  elseif mode == "active" then
    -- pcall keeps the native message free of a Lua file:line prefix. It wraps
    -- only the queue, never the prompt.
    local ok, err = pcall(rex.client.queue, "session.select", { session_id = choice })
    if not ok then
      fail(tostring(err))
    end
  elseif mode == "close" then
    -- Choosing the row is the whole decision: this mode asks for no
    -- confirmation. The binary destroys exactly this ID, never a substitute.
    manager.run("kill", "--", choice)
  elseif mode == "delete" then
    -- The first call removes nothing: it locates the preset and returns the
    -- binary's confirmation menu. Only an explicit "delete" removes the file;
    -- running sessions are never touched.
    local target = manager.run("delete", "--", choice)
    if ask("delete", target.menu) ~= "delete" then
      return {}
    end
    manager.run("delete", "--confirmed", "--", choice)
  else
    -- A new preset is written at once. An existing one is only reported, with
    -- the binary's overwrite menu; replacing it passes the confirmed name, so
    -- a session renamed meanwhile is refused instead of replacing another.
    local saved = manager.run("save", "--", choice)
    if saved.status == "exists" then
      if ask("overwrite", saved.menu) ~= "overwrite" then
        return {}
      end
      manager.run("save", "--overwrite", saved.name, "--", choice)
    end
  end
  return {}
end

local M = {}

-- Register the `session_manager` action and its five keys. Call once, with
-- the prefix declared by init.lua.
function M.setup(PREFIX)
  rex.action{
    name = "session_manager",
    title = "Session Manager",
    description = "Browse project presets, switch running sessions by ID, close one at once, save one as a preset, or delete a preset.",
    category = "Sessions",
    keywords = "projects presets active close save delete picker",
    args = ARGS,
    run = session_manager,
  }

  -- Prefix+s browses every project preset; Prefix+Ctrl+S switches to a running
  -- session; Prefix+Ctrl+K closes the chosen session at once; Prefix+Ctrl+W
  -- saves the chosen session as a preset; Prefix+Ctrl+D deletes the chosen
  -- preset after a confirmation. The native Rex picker stays on Prefix+Ctrl+X.
  rex.bind(PREFIX .. ">s", "session_manager", { mode = "projects" })
  rex.bind(PREFIX .. ">ctrl+s", "session_manager", { mode = "active" })
  rex.bind(PREFIX .. ">ctrl+k", "session_manager", { mode = "close" })
  rex.bind(PREFIX .. ">ctrl+w", "session_manager", { mode = "save" })
  rex.bind(PREFIX .. ">ctrl+d", "session_manager", { mode = "delete" })
end

return M
