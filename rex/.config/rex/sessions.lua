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
-- `rex-session-manager` binary. Its bridge, `rex_session_manager.lua`,
-- registers the `jump_project` action (init.lua calls its `setup` first); this
-- module only binds the native session keys and the project keys. The binary
-- reads the presets on every jump, so a preset change needs no
-- `rex config reload`.

local M = {}

-- Bind the native session shortcuts and the project keys. Call once, with the
-- prefix declared by init.lua, after the bridge's setup.
function M.setup(PREFIX)
  -- Sessions (Herdr workspaces). Prefix+Ctrl+X keeps tmux's session-manager
  -- role by opening Rex's native picker. The session menus live in
  -- rex_session_manager.lua. shift+n/w/d stay here.
  rex.bind(PREFIX .. ">ctrl+x", "session.switch")
  rex.bind(PREFIX .. ">shift+n", "session.new")
  rex.bind(PREFIX .. ">shift+w", "session.rename")
  rex.bind(PREFIX .. ">shift+d", "session.close")

  -- Project keys for presets that exist right now. Plain `s` is the project
  -- browser and always reaches every preset, so no key is needed for a preset
  -- to be usable. `q`, `w`, `e`, and `r` are not project keys: they jump to
  -- marks 1-4 (rex_session_manager.lua), and the marks menu reaches the rest.
  rex.bind(PREFIX .. ">,", "jump_project", { project = "dotfiles" })
  rex.bind(PREFIX .. ">n", "jump_project", { project = "nvim" })
  rex.bind(PREFIX .. ">-", "jump_project", { project = "notes" })
end

return M
