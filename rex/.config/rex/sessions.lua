-- Session management and project jumps for the Rex config beside this file.
--
-- `init.lua` keeps the prefix and calls `require("sessions").setup(PREFIX)`, so
-- both files use one prefix value. This module keeps the project presets, the
-- `jump_project` action, and the read-only `list_projects` action the fzf manager
-- browses. `session_management.lua` owns the manager keys and menus. Change a
-- project here, then run `rex config reload` (or reload from the palette).

local SHELL_FLAVOR = "com.superlogical.terminal.shell"
local FISH = "/opt/homebrew/bin/fish"

-- Project jumps. Each project lists its tabs: the tab title, the working
-- directory, and the program to run. Every tab starts the same interactive
-- fish; a tab with `run` types that command into it as startup input, so the
-- original shell returns when the program exits. A tab without `run` is a plain
-- shell tab. No Kitty file is read at runtime.
local PROJECT_TABS = {
  finaipro = {
    { label = "nvim", cwd = "~/documents/work/finaipro/Web-Finaipro", run = "nvim" },
    { label = "server", cwd = "~/documents/work/finaipro/Web-Finaipro", run = "bun run dev:local" },
    { label = "pi", cwd = "~/documents/work/finaipro/Web-Finaipro", run = "pi" },
  },
  centai = {
    { label = "nvim", cwd = "~/documents/work/finaipro/Web-CentAI-Manager/", run = "nvim" },
    { label = "server", cwd = "~/documents/work/finaipro/Web-CentAI-Manager/", run = "bun run dev" },
    { label = "pi", cwd = "~/documents/work/finaipro/Web-CentAI-Manager/", run = "pi" },
  },
  ["sql-finaipro"] = {
    { label = "nvim", cwd = "~/Documents/work/finaipro/SQLDB-parameters-FinAIPro/", run = "nvim" },
  },
  sergio = {
    { label = "nvim", cwd = "~/documents/personal/sergio", run = "nvim" },
    { label = "server", cwd = "~/documents/personal/sergio", run = "bun run dev" },
    { label = "pi", cwd = "~/documents/personal/sergio", run = "pi" },
  },
  ["conectea-web"] = {
    { label = "nvim", cwd = "~/documents/work/finaipro/conectea-web/", run = "nvim" },
    { label = "server", cwd = "~/documents/work/finaipro/conectea-web/", run = "pnpm run dev" },
    { label = "shell", cwd = "~/documents/work/finaipro/conectea-web/" },
  },
  ["conectea-jea"] = {
    { label = "nvim", cwd = "~/documents/work/finaipro/conectea-jea/", run = "nvim" },
    { label = "server", cwd = "~/documents/work/finaipro/conectea-jea/", run = "pnpm run dev" },
    { label = "shell", cwd = "~/documents/work/finaipro/conectea-jea/" },
  },
  dotfiles = {
    { label = "nvim", cwd = "~/dotfiles", run = "nvim" },
    { cwd = "~/dotfiles" },
  },
  nvim = {
    { label = "nvim", cwd = "~/.config/nvim", run = "nvim" },
    { label = "shell", cwd = "~/.config/nvim" },
  },
  notes = {
    {
      label = "nvim",
      cwd = "~/Library/Mobile Documents/iCloud~md~obsidian/Documents/notes",
      run = "nvim",
    },
    {
      label = "nvim",
      cwd = "/Users/camilo/Library/CloudStorage/OneDrive-FINAIPROTECHNOLOGIESSAS/Finaipro Web Wiki",
      run = "nvim",
    },
  },
}

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
    if tab.label then
      windows[index].window_label = tab.label
    end
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

  -- The fzf manager browses all presets, including the four without a direct
  -- key. Only names leave this module; the tabs stay private.
  rex.action{
    name = "list_projects",
    title = "List Projects",
    description = "Return the configured project names in sorted order.",
    category = "Sessions",
    keywords = "fzf manager presets",
    run = function()
      local names = {}
      for name in pairs(PROJECT_TABS) do
        names[#names + 1] = name
      end
      table.sort(names)
      return { projects = names }
    end,
  }

  -- Reuse the session whose label matches the project, or create it from the
  -- template in one all-or-nothing session.create. The select is queued, so it
  -- runs after this action returns.
  rex.action{
    name = "jump_project",
    title = "Jump to Project",
    args = { project = "string" },
    run = function(_, args)
      local tabs = PROJECT_TABS[args.project]
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
