-- Bridge to the `rex-session-manager` binary for the Rex config beside this file.
--
-- The binary (source in ~/personal/rex-session-manager, installed into
-- ~/.cargo/bin with `cargo install --path .`) owns the session logic: it reads and validates
-- the project presets in `sessions/`, lists, creates, and destroys sessions
-- through `rex api call`, and builds the menus. Only two things stay in Lua,
-- because only Lua can do them:
--
-- * `rex.ui.pick`, which asks only from inside an action's `run` (see
--   session_management.lua);
-- * `rex.client.queue("session.select", ...)`, which shows a session in the
--   invoking app after the action returns.
--
-- Every binary call passes `--sessions-dir` explicitly, so the presets are the
-- ones beside this config even when the config is copied elsewhere. The binary
-- reads them on every call: a preset change needs no `rex config reload`.

-- An absolute path: actions run with Rex.app's restricted PATH, which does not
-- include ~/.cargo/bin (`rex do -e` uses the CLI's PATH, so it hides this).
local NAME = "rex-session-manager"
-- Read HOME without failing the config load: a missing HOME surfaces as a
-- "did not run" error when an action runs.
local BINARY = (os.getenv("HOME") or "") .. "/.cargo/bin/" .. NAME
local SESSIONS_DIRECTORY = "sessions"

-- Rex prepends the loaded config's directory to package.path, so the first
-- entry names the directory holding this module.
local function config_directory()
  local entry = package.path:match("^([^;]+)")
  local directory = entry and entry:match("^(.*)%?%.lua$")
  directory = directory and directory:gsub("/+$", "")
  if directory == nil or directory == "" then
    error("cannot locate the Rex config directory from package.path", 0)
  end
  return directory
end

local SESSIONS_PATH = config_directory() .. "/" .. SESSIONS_DIRECTORY

local M = {}

M.SESSIONS_PATH = SESSIONS_PATH

-- Run the binary with the given arguments and decode its JSON output. A
-- command that prints nothing (`kill`) returns an empty table. Any failure
-- raises the binary's own message plus its exit status.
function M.run(...)
  local result, exec_error = rex.exec{ BINARY, "--sessions-dir", SESSIONS_PATH, ... }
  if type(result) ~= "table" then
    error(NAME .. " did not run: " .. tostring(exec_error or result), 0)
  end
  if result.ok ~= true then
    -- The binary already prefixes its messages with its name; keep one.
    local reason = tostring(result.stderr or "")
      :gsub("^" .. NAME:gsub("%-", "%%-") .. ": ", "")
      :gsub("%s+$", "")
    error(
      ("%s exited %s%s"):format(
        NAME,
        tostring(result.code),
        reason ~= "" and (": " .. reason) or ""
      ),
      0
    )
  end

  local output = tostring(result.stdout or "")
  if output:match("^%s*$") then
    return {}
  end
  -- rex.json.decode returns nil plus a reason instead of raising.
  local decoded, reason = rex.json.decode(output)
  if decoded == nil then
    error(NAME .. " printed invalid JSON: " .. tostring(reason), 0)
  end
  return decoded
end

-- Reuse or create the project's session, then show it in the invoking client.
-- The select is queued, so it runs after the calling action returns.
function M.jump(project)
  local target = M.run("jump", "--", project)
  rex.client.queue("session.select", {
    session_id = target.session_id,
    window_id = target.window_id,
  })
  return target
end

return M
