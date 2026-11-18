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

-- Prefix+Ctrl+H then a: mark the session this key press names. When the press names
-- none, ask which running session to mark first, over the same live list the
-- save menu shows. Marking is silent, because Rex's Lua has no notification
-- API; a failure raises the binary's own message instead. The binary writes the
-- preset first when the session has none, and never duplicates a mark.
local function mark_session(ctx)
  local session_id = ctx.session_id
  if session_id == nil or session_id == "" then
    if ctx.client_id == nil or ctx.client_id == "" then
      fail(
        "mark_session needs the invoking client to ask which session to mark;"
          .. " run it from a Rex shortcut or pass -C"
      )
    end
    local menu = manager.run("menu", "save")
    if menu.items == nil or #menu.items == 0 then
      return {}
    end
    session_id = ask("mark", menu)
    if session_id == nil then
      return {}
    end
  end
  manager.run("mark", "--", session_id)
  return {}
end

-- Prefix+Ctrl+H then m: the marks menu. Choosing a mark jumps to it, and the
-- binary's last row opens a second prompt that removes the chosen mark; that
-- row's id is the binary's `unmark_id`, which never equals a mark's name. There
-- is no separate unmark key, so this menu is the only way to remove a mark.
-- Escape at either prompt changes nothing.
local function marks_menu(ctx)
  if ctx.client_id == nil or ctx.client_id == "" then
    fail("marks_menu needs the invoking client; run it from a Rex shortcut or pass -C")
  end

  local menu = manager.run("menu", "marks")
  if menu.items == nil or #menu.items == 0 then
    return {}
  end
  local choice = ask("marks", menu)
  if choice == nil then
    return {}
  end

  if choice == menu.unmark_id then
    -- The first prompt removed nothing: the second one names the mark to
    -- remove, and only an accepted row removes it.
    local marked = manager.run("menu", "unmark")
    if marked.items == nil or #marked.items == 0 then
      return {}
    end
    local name = ask("unmark", marked)
    if name == nil then
      return {}
    end
    manager.run("unmark", "--", name)
    return {}
  end

  -- A mark with no running session and no preset fails inside the binary with
  -- an error naming the mark and saying to unmark it.
  manager.jump_mark("--", choice)
  return {}
end

-- Prefix+q/w/e/r: jump to mark 1-4 by position, the way a project jump works
-- by preset name. Positions past 4 have no key; the marks menu reaches them.
local function jump_mark(_, args)
  local target = manager.jump_mark("--position", args.position)
  return { session_id = target.session_id }
end

local M = {}

-- Register the `session_manager` action and its keys. Call once, with the
-- prefix declared by init.lua.
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

  -- Marks. The binary keeps the ordered list in <MARKS_PATH>/marks.json and
  -- computes each mark's key from its position, so the menu shows the same
  -- letters these keys use.
  rex.action{
    name = "mark_session",
    title = "Mark Session",
    description = "Mark the current session as one of q, w, e, r, saving it as a preset first when it has none. When the key press names no session, asks which running session to mark.",
    category = "Sessions",
    keywords = "mark harpoon add pin q w e r",
    run = mark_session,
  }
  rex.action{
    name = "marks_menu",
    title = "Marks Menu",
    description = "Jump to a mark saved in "
      .. manager.MARKS_PATH
      .. "/marks.json, or remove one from the same menu.",
    category = "Sessions",
    keywords = "marks harpoon jump unmark remove",
    run = marks_menu,
  }
  rex.action{
    name = "jump_mark",
    title = "Jump to Mark",
    description = "Jump to the mark at a position: its running session, its preset, or a new session from that preset.",
    category = "Sessions",
    keywords = "marks harpoon position q w e r",
    args = { position = "string" },
    run = jump_mark,
  }

  -- Ctrl+H then a / m, chosen by the user. Prefix+Ctrl+H is bound to nothing
  -- else, so plain Prefix+h keeps focusing the left pane without waiting.
  rex.bind(PREFIX .. ">ctrl+h>a", "mark_session")
  rex.bind(PREFIX .. ">ctrl+h>m", "marks_menu")

  -- q, w, e, r are marks 1-4, not project presets. The position travels as a
  -- string, like every other action argument.
  for position, key in ipairs({ "q", "w", "e", "r" }) do
    rex.bind(PREFIX .. ">" .. key, "jump_mark", { position = tostring(position) })
  end
end

return M
