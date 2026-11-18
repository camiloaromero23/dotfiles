-- Session manager menus for the Rex config beside this file.
--
-- `sessions.lua` owns the project presets (loaded from the JSON files in
-- `sessions/`) and the `jump_project` action. This module only browses them and
-- manages running sessions, asking in the command palette through the native
-- `rex.ui.pick` prompt. Escape cancels without creating, selecting, or closing
-- anything; closing destroys the chosen session at once.
--
-- `rex.ui.pick` only asks from inside an action's `run` function and the
-- functions it calls directly. A key-bound closure, a `pcall`/`xpcall` wrapper,
-- a handler registered with `rex.on`, or a function reached through
-- `rex.invoke` gets `nil, "failed"` instead of a prompt. Every path below stays
-- on this call stack for that reason; do not wrap the `ask` call in `pcall`,
-- and keep the keys bound to this action's name.
--
-- `init.lua` keeps the prefix and calls `require("session_management").setup(PREFIX)`.

-- Every row of every menu uses this icon. The app styles each name itself, so
-- change this one value to restyle all three menus at once.
local ROW_ICON = "code"

local MODES = {
  projects = {
    title = "Select Session",
    confirm = "Open Session",
  },
  active = {
    title = "Active Sessions 🟢",
    confirm = "Switch Session",
  },
  close = {
    title = "Kill Session 💀",
    -- The choice itself is the whole decision, so the row that commits it says
    -- what it does.
    confirm = "Close Session",
  },
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

local function fail(message)
  error(message, 0)
end

local function checked(result, err)
  if result == nil then
    fail(tostring(err))
  end
  return result
end

-- Match the old display sanitization without damaging UTF-8 continuation bytes:
-- a raw control character in a label would corrupt the palette row.
local function safe_label(value)
  return tostring(value or ""):gsub("[%z\1-\31\127]", "?"):gsub("\194[\128-\159]", "?")
end

local function project_items(listed)
  local items = {}
  for _, project in ipairs(listed.projects or {}) do
    if type(project) == "string" and project ~= "" then
      items[#items + 1] = { id = project, title = project, icon = ROW_ICON }
    end
  end
  return items
end

local function session_items(sessions)
  local counts = {}
  for _, session in ipairs(sessions) do
    local label = safe_label(session and session.label)
    counts[label] = (counts[label] or 0) + 1
  end

  local items = {}
  for _, session in ipairs(sessions) do
    local id = tostring(session and session.session_id or "")
    if id ~= "" then
      local label = safe_label(session.label)
      local item = {
        id = id,
        title = label == "" and "(unlabelled)" or label,
        icon = ROW_ICON,
      }
      -- Labels are neither unique nor stable, and the prompt requires unique
      -- ids. The id in the subtitle keeps a repeated label readable without
      -- rewriting the title.
      if counts[label] > 1 then
        item.subtitle = id
      end
      items[#items + 1] = item
    end
  end
  return items
end

-- The only call that asks the person. It must run on the action's own stack:
-- see the note at the top of this file before moving it behind an `invoke` or
-- a `pcall`.
local function ask(mode, items)
  local menu = MODES[mode]
  local id, why, detail = rex.ui.pick{
    title = menu.title,
    confirm = menu.confirm,
    items = items,
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

  -- The prompt is delivered through this client, and both jump_project and
  -- session.select act on it. Guessing a client could act on another app.
  if ctx.client_id == nil or ctx.client_id == "" then
    fail("session_manager needs the invoking client; run it from a Rex shortcut or pass -C")
  end

  if mode == "projects" then
    local items = project_items(checked(rex.invoke("list_projects")))
    if #items == 0 then
      return {}
    end
    local project = ask(mode, items)
    if project == nil then
      return {}
    end
    checked(rex.invoke("jump_project", { project = project }))
    return {}
  end

  local items = session_items(checked(rex.call("session.list", {})).sessions or {})
  if #items == 0 then
    return {}
  end
  local session_id = ask(mode, items)
  if session_id == nil then
    return {}
  end

  if mode == "active" then
    local ok, err = pcall(rex.client.queue, "session.select", { session_id = session_id })
    if not ok then
      fail(tostring(err))
    end
    return {}
  end

  -- Choosing the row is the whole decision: this mode asks for no confirmation.
  -- Attach authorizes this connection for the same exact ID; it does not select
  -- a session in the app. Never substitute an ID.
  checked(rex.call("session.attach", { session_id = session_id }))
  checked(rex.call("session.destroy", { session_id = session_id }))
  return {}
end

local M = {}

-- Register the `session_manager` action and its three keys. Call once, with
-- the prefix declared by init.lua.
function M.setup(PREFIX)
  rex.action{
    name = "session_manager",
    title = "Session Manager",
    description = "Browse project presets, switch running sessions by ID, or close one at once.",
    category = "Sessions",
    keywords = "projects presets active close picker",
    args = ARGS,
    run = session_manager,
  }

  -- Prefix+s browses every project preset; Prefix+Ctrl+S switches to a running
  -- session; Prefix+Ctrl+K closes the chosen session at once. The native Rex
  -- picker stays on Prefix+Ctrl+X.
  rex.bind(PREFIX .. ">s", "session_manager", { mode = "projects" })
  rex.bind(PREFIX .. ">ctrl+s", "session_manager", { mode = "active" })
  rex.bind(PREFIX .. ">ctrl+k", "session_manager", { mode = "close" })
end

return M
