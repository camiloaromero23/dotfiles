-- Session shortcuts and project jumps for the Rex config beside this file.
--
-- `init.lua` keeps the prefix and calls `require("sessions").setup(PREFIX)`, so
-- both files use one prefix value. The project presets live in the `sessions/`
-- directory beside this file, one JSON file per project:
--
--   {
--     "name": "dotfiles",
--     "tabs": [
--       { "cwd": "~/dotfiles", "run": "nvim" },
--       { "cwd": "~/dotfiles" }
--     ]
--   }
--
-- Loading, validating, and turning a preset into a session is done by the
-- `rex-session-manager` binary through `rex_session_manager.lua`; this module
-- only registers the `jump_project` action and the keys. The binary reads the
-- presets on every jump, so a preset change needs no `rex config reload`.

local manager = require("rex_session_manager")

local M = {}

-- Register the native session shortcuts, the `jump_project` action, and the
-- project keys. Call once, with the prefix declared by init.lua.
function M.setup(PREFIX)
  -- Sessions (Herdr workspaces). Prefix+Ctrl+X keeps tmux's session-manager
  -- role by opening Rex's native picker. The session menus live in
  -- session_management.lua. shift+n/w/d stay here.
  rex.bind(PREFIX .. ">ctrl+x", "session.switch")
  rex.bind(PREFIX .. ">shift+n", "session.new")
  rex.bind(PREFIX .. ">shift+w", "session.rename")
  rex.bind(PREFIX .. ">shift+d", "session.close")

  -- Reuse the session whose label matches the project, or create it from the
  -- preset in one all-or-nothing session.create, then select it.
  rex.action{
    name = "jump_project",
    title = "Jump to Project",
    description = "Open the project preset from "
      .. manager.SESSIONS_PATH
      .. ", reusing its session when one is running.",
    args = { project = "string" },
    run = function(_, args)
      local target = manager.jump(args.project)
      return { session_id = target.session_id }
    end,
  }

  -- Project keys for presets that exist right now. Plain `s` is the project
  -- browser and always reaches every preset, so no key is needed for a preset
  -- to be usable. `q`, `w`, `e`, and `r` are not project keys: they jump to
  -- marks 1-4 (session_management.lua), and the marks menu reaches the rest.
  rex.bind(PREFIX .. ">,", "jump_project", { project = "dotfiles" })
  rex.bind(PREFIX .. ">n", "jump_project", { project = "nvim" })
  rex.bind(PREFIX .. ">-", "jump_project", { project = "notes" })
end

return M
