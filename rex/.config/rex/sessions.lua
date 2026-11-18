-- Session management and project jumps for the Rex config beside this file.
--
-- `init.lua` keeps the prefix and calls `require("sessions").setup(PREFIX)`, so
-- both files use one prefix value. This module loads the project presets from
-- the `sessions/` directory beside it, keeps the `jump_project` action, and
-- exposes the read-only `list_projects` action the fzf manager browses.
-- `session_management.lua` owns the manager keys and menus. The presets are
-- read from disk on every `list_projects` and `jump_project` call, so creating,
-- editing, or deleting a preset file takes effect the next time a menu opens or
-- a jump runs: no `rex config reload` is needed for a preset change, only for a
-- change to this Lua file.
--
-- A preset file is one JSON object:
--
--   {
--     "name": "dotfiles",
--     "tabs": [
--       { "cwd": "~/dotfiles", "run": "nvim" },
--       { "cwd": "~/dotfiles" }
--     ]
--   }
--
-- `name` is required, unique across files, and is what `jump_project` and the
-- keybindings below use; the file name is only for humans. `tabs` is a
-- non-empty array: `cwd` is required, `run` is the optional program typed into
-- that tab. Every tab starts the same interactive fish, so a tab with `run`
-- returns to the original shell when the program exits. A tab without `run` is
-- a plain shell tab. Nothing here names a tab: Rex generates their titles
-- (`Workspace.prefersGeneratedTitles` in preferences.plist).

local SHELL_FLAVOR = "com.superlogical.terminal.shell"
local FISH = "/opt/homebrew/bin/fish"
local SESSIONS_DIRECTORY = "sessions"

-- Top-level and per-tab keys this module understands. An unknown key is a hard
-- error: a typo such as "command" or "dir" would otherwise load a preset that
-- silently ignores what it was meant to configure.
local PROJECT_KEYS = { name = true, tabs = true }
local TAB_KEYS = { cwd = true, run = true }

-- Rex prepends the loaded config's directory to package.path, so the first
-- entry names the directory holding this module. That keeps the presets beside
-- a copied config, including a path with spaces, with no extra setup.
local function config_directory()
  local entry = package.path:match("^([^;]+)")
  if entry == nil then
    return nil
  end
  local directory = entry:match("^(.*)%?%.lua$")
  if directory == nil or directory == "" then
    return nil
  end
  -- package.path entries end with a separator; keep joined paths double-slash free.
  directory = directory:gsub("/+$", "")
  if directory == "" then
    return nil
  end
  return directory
end

local function read_file(path)
  local file, open_error = io.open(path, "r")
  if file == nil then
    error("cannot read " .. path .. ": " .. tostring(open_error), 0)
  end
  local content, read_error = file:read("*a")
  file:close()
  if content == nil then
    -- io.open succeeds on a directory on macOS; the reason only arrives here.
    error("cannot read " .. path .. ": " .. tostring(read_error), 0)
  end
  return content
end

-- `ls -1` is the only listing Rex offers: it blocks io.popen and ships no
-- filesystem module. `rex.exec` runs at config load time and returns
-- ok/code/stdout/stderr.
local function list_directory(directory)
  local result = rex.exec{ "ls", "-1", directory }
  if type(result) ~= "table" or result.ok ~= true then
    -- Always name the exit status: stderr alone is empty for some failures.
    local code = type(result) == "table" and result.code or "unknown"
    local reason = ""
    if type(result) == "table" and result.stderr ~= nil then
      reason = tostring(result.stderr)
    elseif type(result) ~= "table" then
      reason = tostring(result)
    end
    reason = reason:gsub("%s+$", "")
    local detail = reason ~= "" and (": " .. reason) or ""
    error(
      ("cannot list %s: ls exited %s%s"):format(directory, tostring(code), detail),
      0
    )
  end
  local entries = {}
  for entry in tostring(result.stdout):gmatch("[^\r\n]+") do
    entries[#entries + 1] = entry
  end
  return entries
end

local function reject_unknown_keys(table_value, allowed, path, label)
  for key in pairs(table_value) do
    if allowed[key] ~= true then
      error(
        ("%s: %s has unknown key %q"):format(path, label, tostring(key)),
        0
      )
    end
  end
end

local function validate_tab(tab, path, index)
  local label = "tab " .. tostring(index)
  if type(tab) ~= "table" then
    error(("%s: %s is not an object"):format(path, label), 0)
  end
  if type(tab.cwd) ~= "string" or tab.cwd == "" then
    error(("%s: %s needs a non-empty string \"cwd\""):format(path, label), 0)
  end
  if tab.run ~= nil and (type(tab.run) ~= "string" or tab.run == "") then
    error(
      ("%s: %s has a \"run\" that is not a non-empty string"):format(path, label),
      0
    )
  end
  reject_unknown_keys(tab, TAB_KEYS, path, label)
end

-- Returns the tabs for one decoded preset, or raises an error naming the file
-- and the field, so a broken preset never silently disappears from the menus.
local function validate_project(decoded, path)
  if type(decoded) ~= "table" then
    error(path .. ": the file must contain a JSON object", 0)
  end
  if type(decoded.name) ~= "string" or decoded.name == "" then
    error(path .. ": needs a non-empty string \"name\"", 0)
  end
  if type(decoded.tabs) ~= "table" then
    error(path .. ": needs a \"tabs\" array", 0)
  end
  reject_unknown_keys(decoded, PROJECT_KEYS, path, "project")

  local tabs = {}
  for key in pairs(decoded.tabs) do
    if type(key) ~= "number" then
      error(path .. ": \"tabs\" must be an array, not an object", 0)
    end
  end
  for index = 1, #decoded.tabs do
    validate_tab(decoded.tabs[index], path, index)
    tabs[index] = {
      cwd = decoded.tabs[index].cwd,
      run = decoded.tabs[index].run,
    }
  end
  if #tabs == 0 then
    error(path .. ": needs at least one tab", 0)
  end

  return { name = decoded.name, tabs = tabs }
end

-- Resolve the directory holding the preset files. Cheap and side-effect free,
-- so it runs on every action; only listing and reading touch the disk.
local function sessions_directory()
  local directory = config_directory()
  if directory == nil then
    error("cannot locate the Rex config directory from package.path", 0)
  end
  return directory .. "/" .. SESSIONS_DIRECTORY
end

-- Read every `*.json` file in the sessions directory, in file-name order so the
-- fzf menu is deterministic. The extension match ignores case, so a file named
-- `FINAIPRO.JSON` still loads instead of disappearing; other entries (README,
-- .DS_Store) and hidden files (`ls -1` omits them) are ignored.
--
-- Called on every action rather than at config load, so a preset added or
-- deleted on disk is visible immediately. The cost is a directory listing and a
-- handful of small reads per menu open.
local function load_projects()
  local directory = sessions_directory()

  local files = {}
  for _, entry in ipairs(list_directory(directory)) do
    if entry:match("%.[jJ][sS][oO][nN]$") then
      files[#files + 1] = entry
    end
  end
  table.sort(files)
  if #files == 0 then
    error("no project session files in " .. directory, 0)
  end

  local projects = {}
  local sources = {}
  for _, entry in ipairs(files) do
    local path = directory .. "/" .. entry
    local content = read_file(path)
    -- rex.json.decode reports failure by returning nil plus a reason rather
    -- than raising; keep the pcall for safety and check both cases.
    local ok, parsed, decode_reason = pcall(rex.json.decode, content)
    if not ok then
      error("cannot parse " .. path .. ": " .. tostring(parsed), 0)
    end
    if parsed == nil then
      error("cannot parse " .. path .. ": " .. tostring(decode_reason), 0)
    end
    local project = validate_project(parsed, path)
    if projects[project.name] ~= nil then
      error(
        ("duplicate project %q in %s and %s"):format(
          project.name,
          sources[project.name],
          path
        ),
        0
      )
    end
    projects[project.name] = project.tabs
    sources[project.name] = path
  end
  return projects
end

local SESSIONS_PATH = sessions_directory()

-- A leading ~/ is the only thing expanded, so paths with spaces stay literal.
local function expand_home(path)
  local home = os.getenv("HOME")
  if home and home ~= "" and path:sub(1, 2) == "~/" then
    return home .. path:sub(2)
  end
  return path
end

local function project_windows(tabs)
  local windows = {}
  for index, tab in ipairs(tabs) do
    local options = {
      cwd = expand_home(tab.cwd),
      command = { FISH, "--login", "--interactive" },
      shell = "none",
    }
    if tab.run then
      -- Type the program into the interactive fish. It runs in the foreground,
      -- so the terminal reports it as the foreground process; the original
      -- shell returns when it exits.
      options.initial_input = tab.run .. "\n"
    end
    windows[index] = { layout = rex.layout.block{ flavor = SHELL_FLAVOR, options = options } }
  end
  return windows
end

local M = {}

-- Register the native session shortcuts, the project actions, and the five
-- project keys. Call once, with the prefix declared by init.lua.
function M.setup(PREFIX)
  -- Sessions (Herdr workspaces). Prefix+Ctrl+X keeps tmux's session-manager
  -- role by opening Rex's native picker. The fzf menus live in
  -- session_management.lua. shift+n/w/d stay here.
  rex.bind(PREFIX .. ">ctrl+x", "session.switch")
  rex.bind(PREFIX .. ">shift+n", "session.new")
  rex.bind(PREFIX .. ">shift+w", "session.rename")
  rex.bind(PREFIX .. ">shift+d", "session.close")

  -- The fzf manager browses every loaded preset, including the four without a
  -- direct key. Only names leave this module; the tabs stay private.
  rex.action{
    name = "list_projects",
    title = "List Projects",
    description = "Return the project names loaded from "
      .. SESSIONS_PATH
      .. ", sorted. Reads the directory on every call, so no reload is needed.",
    category = "Sessions",
    keywords = "fzf manager presets",
    run = function()
      local projects = load_projects()
      local names = {}
      for name in pairs(projects) do
        names[#names + 1] = name
      end
      table.sort(names)
      return { projects = names }
    end,
  }

  -- Reuse the session whose label matches the project, or create it from the
  -- preset in one all-or-nothing session.create. The select is queued, so it
  -- runs after this action returns.
  rex.action{
    name = "jump_project",
    title = "Jump to Project",
    args = { project = "string" },
    run = function(_, args)
      -- Re-read the directory per call: a preset created or deleted since the
      -- menu opened must not need a config reload.
      local projects = load_projects()
      local tabs = projects[args.project]
      if tabs == nil then
        error("unknown project: " .. tostring(args.project), 0)
      end

      local listed, list_error = rex.call("session.list", {})
      if listed == nil then
        error("session.list failed: " .. tostring(list_error), 0)
      end
      local matches = {}
      for _, session in ipairs(listed.sessions or {}) do
        if session.label == args.project then
          matches[#matches + 1] = session
        end
      end
      if #matches > 1 then
        error("more than one session is labelled " .. args.project, 0)
      end

      local session_id
      local window_id
      if matches[1] then
        session_id = matches[1].session_id
      else
        local created, create_error = rex.call("session.create", {
          label = args.project,
          initial_windows = project_windows(tabs),
        })
        if created == nil then
          error("session.create failed: " .. tostring(create_error), 0)
        end
        session_id = created.session_id
        window_id = created.initial_windows[1].window_id
      end

      rex.client.queue("session.select", { session_id = session_id, window_id = window_id })
      return { session_id = session_id }
    end,
  }

  -- Current project shortcuts. Reload stays on Shift+R, the native session
  -- picker remains on Ctrl+X, and split-down stays on Shift+'. p still goes to
  -- the previous tab. Other presets remain available through jump_project and
  -- the fzf project menu.
  rex.bind(PREFIX .. ">q", "jump_project", { project = "finaipro" })
  rex.bind(PREFIX .. ">w", "jump_project", { project = "sql-finaipro" })
  rex.bind(PREFIX .. ">,", "jump_project", { project = "dotfiles" })
  rex.bind(PREFIX .. ">n", "jump_project", { project = "nvim" })
  rex.bind(PREFIX .. ">-", "jump_project", { project = "notes" })
end

return M
