-- Interactive session picker, run locally by `rex do` inside the popup.
-- The launcher pins REX_CLIENT; REX_SERVER selects the inherited server.
-- Usage: REX_CLIENT=CLIENT rex --autostart=false do ./session_picker.lua mode=projects
-- Modes: projects | active | close. The launcher also passes interactive=true
-- so errors wait for Enter; direct/noninteractive callers do not wait.
-- No standalone Lua, Bash, jq, or shell interpolation is involved.

local TITLES = {
  projects = "rex-session-manager",
  active = "rex-session-manager (active-sessions)",
  close = "rex-session-manager (kill-session)",
}

local THEME = [[
    --color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8
    --color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC
    --color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8
    --color=selected-bg:#45475A
    --color=border:#6C7086,label:#CDD6F4
]]

local function fail(message, status)
  error({ message = message, status = status or 1 }, 0)
end

local function checked(result, err)
  if result == nil then
    fail(tostring(err), 3)
  end
  return result
end

local function call(name, args)
  return checked(rex.call(name, args))
end

local function supplied(name)
  local value = os.getenv(name)
  return value ~= nil and value ~= ""
end

-- Match the old display sanitization without damaging UTF-8 continuation bytes.
local function safe_label(value)
  return tostring(value or ""):gsub("[%z\1-\31\127]", "?"):gsub("\194[\128-\159]", "?")
end

local function tsv(value)
  return value:gsub("\\", "\\\\"):gsub("\t", "\\t"):gsub("\n", "\\n"):gsub("\r", "\\r")
end

local function session_rows(sessions)
  local counts, rows, listed = {}, {}, {}
  for _, session in ipairs(sessions) do
    local label = safe_label(session.label)
    counts[label] = (counts[label] or 0) + 1
  end
  for _, session in ipairs(sessions) do
    local id = tostring(session.session_id or "")
    local label = safe_label(session.label)
    local display = label == "" and "(unlabelled)" or label
    if counts[label] > 1 then
      display = display .. " [" .. id .. "]"
    end
    display = tsv(display)
    local row = tsv(id) .. "\t" .. display
    rows[#rows + 1] = row
    listed[row] = { id = id, display = display }
  end
  return rows, listed
end

local function choose(rows, mode, fields)
  local env = { REX_CLIENT = false }
  if not supplied("FZF_DEFAULT_OPTS") and not supplied("FZF_DEFAULT_OPTS_FILE") then
    env.FZF_DEFAULT_OPTS = THEME
  end
  local fzf = supplied("FZF_BIN") and os.getenv("FZF_BIN") or "/opt/homebrew/bin/fzf"
  local result = rex.exec({
    fzf,
    "--delimiter=\t",
    "--with-nth=" .. fields,
    "--prompt=> ",
    "--no-height",
    "--margin=0,18%,26%,0",
    "--padding=0",
    "--border=rounded",
    "--border-label=" .. TITLES[mode],
    "--no-multi",
    "--no-clear",
  }, { stdin = table.concat(rows, "\n") .. "\n", env = env })
  if result == nil then
    fail("fzf is not executable: " .. fzf)
  end
  if result.stderr and result.stderr ~= "" then
    io.stderr:write(result.stderr)
  end
  local status = result.code
  if status == 1 or status == 130 or result.signal == "SIGINT" then
    return nil
  end
  if status ~= 0 then
    -- rex.exec reports a signal separately instead of a shell's 128+signal code.
    local signals = { SIGHUP = 1, SIGQUIT = 3, SIGKILL = 9, SIGPIPE = 13, SIGTERM = 15 }
    if status < 0 then
      status = 128 + (signals[result.signal] or 1)
    end
    fail("fzf failed with exit " .. tostring(status), status)
  end
  local selected = (result.stdout or ""):gsub("\n+$", "")
  if selected == "" then
    fail("fzf returned an empty selection")
  end
  return selected
end

local function main()
  local mode = rex.args.mode
  if type(mode) ~= "string" or not TITLES[mode] then
    io.stderr:write("Usage: REX_CLIENT=CLIENT rex do ./session_picker.lua mode=projects|active|close\n")
    fail("unknown mode: " .. tostring(mode), 2)
  end
  if not supplied("REX_CLIENT") then
    fail("REX_CLIENT is not set; run this picker from a Rex shortcut", 2)
  end
  if not supplied("REX_SERVER") then
    fail("REX_SERVER is not set; run this manager from a Rex terminal")
  end

  if mode == "projects" then
    local projects = checked(rex.invoke("list_projects"))
    local rows, listed = {}, {}
    for _, project in ipairs(projects.projects or {}) do
      if project ~= "" then
        rows[#rows + 1] = project
        listed[project] = true
      end
    end
    if #rows == 0 then
      return
    end
    local selected = choose(rows, mode, "1..")
    if selected == nil then
      return
    end
    if not listed[selected] then
      fail("the selection is not one of the listed projects")
    end
    checked(rex.invoke("jump_project", { project = selected }))
    return
  end

  local rows, listed = session_rows(call("session.list", {}).sessions or {})
  if #rows == 0 then
    return
  end
  local selected = choose(rows, mode, "2..")
  if selected == nil then
    return
  end
  local session = listed[selected]
  if session == nil then
    fail("the selection is not one of the listed sessions")
  end
  if session.id == "" then
    fail("the selected row has no session ID")
  end
  if mode == "active" then
    local ok, err = pcall(rex.client.queue, "session.select", { session_id = session.id })
    if not ok then
      fail(tostring(err), 3)
    end
    return
  end

  io.write("Close session " .. session.display .. " (" .. session.id .. ")? [y/N] ")
  io.flush()
  if io.read("*l") ~= "y" then
    io.write("Keeping session " .. session.display .. ".\n")
    return
  end
  -- Attach authorizes this connection for the same exact ID; it does not select
  -- a session in the app. Never destroy before confirmation or substitute an ID.
  call("session.attach", { session_id = session.id })
  call("session.destroy", { session_id = session.id })
end

local ok, err = pcall(main)
local status = 0
if not ok then
  local known = type(err) == "table"
  status = known and err.status or 1
  io.stderr:write("Error: " .. (known and err.message or tostring(err)) .. "\n")
  if rex.args.interactive == true then
    io.write("Press Enter to close.")
    io.flush()
    io.read("*l")
  end
end
rex.stop(status)
