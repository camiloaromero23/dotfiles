#!/usr/bin/env python3
"""Regression tests for the Rex keymap migrated from Herdr and tmux.

``rex config check PATH --json`` loads a temporary copy of ``init.lua`` and its
sibling modules ``sessions.lua`` and ``session_management.lua`` with Lua
assertions appended. Structure is checked through the documented
``rex.bindings()``, ``rex.modes()``, and action report APIs without touching a
live server.

``rex do PATH --action jump_project`` runs the real custom action from a copy
of the same files whose ``rex.call`` and ``rex.client.queue`` are replaced by
recording stubs. ``list_projects`` runs without stubs because it only reads the
private registry. No session is listed, created, or selected.

Not covered: real keystrokes in the app, and app shortcuts that override this file.
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[4]
CONFIG_DIR = REPO_ROOT / "rex" / ".config" / "rex"
INIT_LUA = CONFIG_DIR / "init.lua"
# init.lua loads this sibling module with `require("sessions")`, so every
# temporary copy needs both files for the native loader to resolve it.
SESSIONS_LUA = CONFIG_DIR / "sessions.lua"
SESSION_MANAGEMENT_LUA = CONFIG_DIR / "session_management.lua"
SESSION_MANAGEMENT_SH = CONFIG_DIR / "session_management.sh"
CONFIG_MODULES = (SESSIONS_LUA.name, SESSION_MANAGEMENT_LUA.name)
REX = shutil.which("rex")
PREFIX = "ctrl+a>"
FLAVOR = "com.superlogical.terminal.shell"
FISH_BIN = "/opt/homebrew/bin/fish"
TRACE_PREFIX = "__REX_TRACE__ "
# A HOME that need not exist: the action only expands "~/" as a string.
TEST_HOME = "/tmp/rex-keymap-fake-home"

# Every migrated shortcut: (key, action, exact args). Keys in a mode keep the
# mode prefix, the way rex.bindings() reports them.
BINDINGS = [
    # prefix passthrough and reload
    (f"{PREFIX}ctrl+a", "pane.send_key", {"key": "ctrl+a"}),
    (f"{PREFIX}shift+r", "client.config.reload"),
    # resize mode: Herdr-style movement, arrow keys, two exits
    ("resize/h", "pane.resize", {"direction": "left"}),
    ("resize/j", "pane.resize", {"direction": "down"}),
    ("resize/k", "pane.resize", {"direction": "up"}),
    ("resize/l", "pane.resize", {"direction": "right"}),
    ("resize/left", "pane.resize", {"direction": "left"}),
    ("resize/down", "pane.resize", {"direction": "down"}),
    ("resize/up", "pane.resize", {"direction": "up"}),
    ("resize/right", "pane.resize", {"direction": "right"}),
    ("resize/esc", "client.mode.exit"),
    ("resize/enter", "client.mode.exit"),
    # sessions: fzf manager menus, the native picker, then Herdr workspaces
    (f"{PREFIX}s", "session_manager", {"mode": "projects"}),
    (f"{PREFIX}ctrl+s", "session_manager", {"mode": "active"}),
    (f"{PREFIX}ctrl+k", "session_manager", {"mode": "close"}),
    (f"{PREFIX}ctrl+x", "session.switch"),
    (f"{PREFIX}shift+n", "session.new"),
    (f"{PREFIX}shift+w", "session.rename"),
    (f"{PREFIX}shift+d", "session.close"),
    # project jumps currently bound
    (f"{PREFIX}q", "jump_project", {"project": "finaipro"}),
    (f"{PREFIX}w", "jump_project", {"project": "sql-finaipro"}),
    (f"{PREFIX},", "jump_project", {"project": "dotfiles"}),
    (f"{PREFIX}n", "jump_project", {"project": "nvim"}),
    (f"{PREFIX}-", "jump_project", {"project": "notes"}),
    # tabs
    (f"{PREFIX}c", "client.tab.new"),
    (f"{PREFIX}shift+t", "client.tab.rename"),
    (f"{PREFIX}p", "client.tab.previous"),
    (f"{PREFIX}shift+x", "client.tab.close"),
    # panes: focus wraps at the edge, like tmux select-pane
    (f"{PREFIX}h", "pane.focus", {"direction": "left", "wrap": True}),
    (f"{PREFIX}j", "pane.focus", {"direction": "down", "wrap": True}),
    (f"{PREFIX}k", "pane.focus", {"direction": "up", "wrap": True}),
    (f"{PREFIX}l", "pane.focus", {"direction": "right", "wrap": True}),
    (f"{PREFIX}tab", "pane.focus_next"),
    (f"{PREFIX}shift+tab", "pane.focus_previous"),
    # splits
    (f"{PREFIX}v", "pane.split", {"direction": "right"}),
    (f"{PREFIX}shift+5", "pane.split", {"direction": "right"}),
    (f"{PREFIX}shift+'", "pane.split", {"direction": "down"}),
    # panes and panels
    (f"{PREFIX}x", "client.close"),
    (f"{PREFIX}z", "pane.zoom"),
    (f"{PREFIX}b", "client.sidebar.toggle"),
    (f"{PREFIX}shift+/", "client.palette.toggle"),
    (f"{PREFIX}shift+s", "client.settings"),
] + [(f"{PREFIX}{index}", "client.tab.goto", {"index": index}) for index in range(1, 10)]

# Keys the installed client has no action for: they must stay unbound rather
# than point at a lookalike.
UNSUPPORTED = [
    f"{PREFIX}g",  # goto picker
    f"{PREFIX}o",  # notification target
    f"{PREFIX}shift+p",  # rename pane
    f"{PREFIX}shift+g",  # new worktree
]

LUA_HARNESS = """
local __bindings = {}
for _, b in ipairs(rex.bindings()) do
  __bindings[(b.mode and (b.mode .. "/") or "") .. b.key] = b
end
local __modes = {}
for _, m in ipairs(rex.modes()) do
  __modes[m.name] = m
end
"""

# The project templates in init.lua: the exact tabs, working directories, and
# programs. Program tabs type their command into an interactive fish as startup
# input; a tab without `run` is a plain shell tab with no startup input. The
# second dotfiles tab had no title, so it keeps Rex's own label.
PROJECT_TEMPLATES = {
    "finaipro": [
        {
            "window_label": "nvim",
            "cwd": "~/documents/work/finaipro/Web-Finaipro",
            "run": "nvim",
        },
        {
            "window_label": "server",
            "cwd": "~/documents/work/finaipro/Web-Finaipro",
            "run": "bun run dev:local",
        },
        {
            "window_label": "pi",
            "cwd": "~/documents/work/finaipro/Web-Finaipro",
            "run": "pi",
        },
    ],
    "centai": [
        {
            "window_label": "nvim",
            "cwd": "~/documents/work/finaipro/Web-CentAI-Manager/",
            "run": "nvim",
        },
        {
            "window_label": "server",
            "cwd": "~/documents/work/finaipro/Web-CentAI-Manager/",
            "run": "bun run dev",
        },
        {
            "window_label": "pi",
            "cwd": "~/documents/work/finaipro/Web-CentAI-Manager/",
            "run": "pi",
        },
    ],
    "sql-finaipro": [
        {
            "window_label": "nvim",
            "cwd": "~/Documents/work/finaipro/SQLDB-parameters-FinAIPro/",
            "run": "nvim",
        },
    ],
    "sergio": [
        {
            "window_label": "nvim",
            "cwd": "~/documents/personal/sergio",
            "run": "nvim",
        },
        {
            "window_label": "server",
            "cwd": "~/documents/personal/sergio",
            "run": "bun run dev",
        },
        {
            "window_label": "pi",
            "cwd": "~/documents/personal/sergio",
            "run": "pi",
        },
    ],
    "conectea-web": [
        {
            "window_label": "nvim",
            "cwd": "~/documents/work/finaipro/conectea-web/",
            "run": "nvim",
        },
        {
            "window_label": "server",
            "cwd": "~/documents/work/finaipro/conectea-web/",
            "run": "pnpm run dev",
        },
        {"window_label": "shell", "cwd": "~/documents/work/finaipro/conectea-web/"},
    ],
    "conectea-jea": [
        {
            "window_label": "nvim",
            "cwd": "~/documents/work/finaipro/conectea-jea/",
            "run": "nvim",
        },
        {
            "window_label": "server",
            "cwd": "~/documents/work/finaipro/conectea-jea/",
            "run": "pnpm run dev",
        },
        {"window_label": "shell", "cwd": "~/documents/work/finaipro/conectea-jea/"},
    ],
    "dotfiles": [
        {
            "window_label": "nvim",
            "cwd": "~/dotfiles",
            "run": "nvim",
        },
        {"cwd": "~/dotfiles"},
    ],
    "nvim": [
        {
            "window_label": "nvim",
            "cwd": "~/.config/nvim",
            "run": "nvim",
        },
        {"window_label": "shell", "cwd": "~/.config/nvim"},
    ],
    "notes": [
        {
            "window_label": "nvim",
            "cwd": "~/Library/Mobile Documents/iCloud~md~obsidian/Documents/notes",
            "run": "nvim",
        },
        {
            "window_label": "nvim",
            "cwd": "/Users/camilo/Library/CloudStorage/OneDrive-FINAIPROTECHNOLOGIESSAS/Finaipro Web Wiki",
            "run": "nvim",
        },
    ],
}

# The project jumps the config currently binds. Four more templates (centai,
# sergio, conectea-web, conectea-jea) stay available but unbound.
PROJECT_JUMPS = {
    f"{PREFIX}q": "finaipro",
    f"{PREFIX}w": "sql-finaipro",
    f"{PREFIX},": "dotfiles",
    f"{PREFIX}n": "nvim",
    f"{PREFIX}-": "notes",
}

# Appended to a copy of init.lua for behavioral tests. `__plan__` is the exact
# sequence of API calls the action must make; anything else fails the action.
ACTION_STUBS = """
local __plan = __plan__
local __index = 0

local function __same(a, b)
  if type(a) ~= type(b) then return false end
  if type(a) ~= "table" then return a == b end
  for key, value in pairs(a) do
    if not __same(value, b[key]) then return false end
  end
  for key in pairs(b) do
    if a[key] == nil then return false end
  end
  return true
end

local function __expect(kind)
  __index = __index + 1
  local step = __plan[__index]
  if step == nil then error("unexpected " .. kind .. " call", 0) end
  if step.kind ~= kind then error("expected " .. step.kind .. ", got " .. kind, 0) end
  return step
end

local function __record(step, method, args)
  if step.method ~= method then
    error("expected " .. step.method .. ", got " .. tostring(method), 0)
  end
  if not __same(step.args, args) then
    error("unexpected args for " .. method .. ": " .. rex.json.encode(args), 0)
  end
  io.stderr:write("__REX_TRACE__ " .. rex.json.encode({ kind = step.kind, method = method, args = args }) .. "\\n")
  io.stderr:flush()
end

rex.call = function(method, args)
  local step = __expect("call")
  __record(step, method, args)
  if step.error ~= nil then return nil, step.error end
  return step.result
end

rex.client.queue = function(method, args)
  __record(__expect("queue"), method, args)
end
"""


def json_block(value) -> str:
    """Lua that decodes the same JSON Rex's own encoder emits."""
    return f"rex.json.decode([=[{json.dumps(value)}]=])"


def copy_config(
    scratch: Path,
    suffix: str = "",
    modules: tuple[str, ...] = CONFIG_MODULES,
    copy_helper: bool = True,
    prefix: str = "",
) -> Path:
    """Write an init.lua copy plus the sibling modules and helper it loads."""
    config = scratch / "init.lua"
    config.write_text(
        prefix + INIT_LUA.read_text(encoding="utf-8") + suffix, encoding="utf-8"
    )
    for module in modules:
        shutil.copy(CONFIG_DIR / module, scratch / module)
    if copy_helper:
        shutil.copy(SESSION_MANAGEMENT_SH, scratch / SESSION_MANAGEMENT_SH.name)
    return config


def config_check(*lua_blocks: str) -> dict:
    """Load a temporary copy of init.lua plus assertions with the real parser."""
    if REX is None:
        raise AssertionError("the rex CLI is not on PATH")

    suffix = ""
    if lua_blocks:
        suffix = f"\n{LUA_HARNESS}\n{''.join(lua_blocks)}"

    with tempfile.TemporaryDirectory(prefix="rex-keymap-check-") as scratch:
        config = copy_config(Path(scratch), suffix)
        result = subprocess.run(
            [REX, "config", "check", str(config), "--json"],
            capture_output=True,
            text=True,
            timeout=30,
        )

    try:
        report = json.loads(result.stdout)
    except json.JSONDecodeError:
        raise AssertionError(
            f"rex config check did not return JSON (exit {result.returncode})\n"
            f"stdout: {result.stdout}\nstderr: {result.stderr}"
        ) from None

    if result.returncode != 0:
        problems = "\n".join(
            f"  {item['severity']} {item['source']}: {item['message']}"
            for item in report.get("diagnostics", [])
        )
        raise AssertionError(
            f"rex config check rejected the configuration (exit {result.returncode})\n"
            f"{problems}\nstderr: {result.stderr}"
        )
    return report


def expand_home(path: str) -> str:
    """Expand a leading ~/ with the fake HOME the action runs under."""
    return TEST_HOME + path[1:] if path.startswith("~/") else path


def expected_window(tab: dict) -> dict:
    """The session.create window for one project tab."""
    options = {
        "cwd": expand_home(tab["cwd"]),
        "command": [FISH_BIN, "--login", "--interactive"],
        "shell": "none",
    }
    if "run" in tab:
        # Startup input is typed into interactive fish; the program takes the
        # foreground and the original shell returns when it exits.
        options["initial_input"] = tab["run"] + "\n"
    window = {"layout": {"block": {"flavor": FLAVOR, "options": options}}}
    if "window_label" in tab:
        window["window_label"] = tab["window_label"]
    return window


def created_result(session_id: str, tabs: list[dict]) -> dict:
    """Model ordered tab IDs returned by the public session.create API."""
    return {
        "session_id": session_id,
        "initial_windows": [
            {"window_id": "window:first" if index == 0 else f"window:tab-{index + 1}"}
            for index in range(len(tabs))
        ],
    }


def run_project_action(
    project: str, plan: list[dict]
) -> tuple[subprocess.CompletedProcess, list[dict]]:
    """Run the real jump_project action with recording API stubs."""
    if REX is None:
        raise AssertionError("the rex CLI is not on PATH")

    stubs = ACTION_STUBS.replace("__plan__", json_block(plan))

    with tempfile.TemporaryDirectory(prefix="rex-project-jump-") as scratch:
        config = copy_config(Path(scratch), f"\n{stubs}\n")
        result = subprocess.run(
            [
                REX,
                "--autostart=false",
                "do",
                str(config),
                "--action",
                "jump_project",
                "--args",
                json.dumps({"project": project}),
                "--json",
            ],
            capture_output=True,
            text=True,
            timeout=30,
            env=dict(os.environ, HOME=TEST_HOME),
        )

    trace = [
        json.loads(line[len(TRACE_PREFIX) :])
        for line in result.stderr.splitlines()
        if line.startswith(TRACE_PREFIX)
    ]
    return result, trace


def expected_trace(plan: list[dict]) -> list[dict]:
    return [
        {"kind": step["kind"], "method": step["method"], "args": step["args"]}
        for step in plan
    ]


class KeymapTest(unittest.TestCase):
    def assert_config_accepts(self, *lua_blocks: str) -> dict:
        return config_check(*lua_blocks)

    def assert_bindings(self, expected: list[dict]) -> None:
        self.assert_config_accepts(
            f"""
local problems = {{}}
for _, want in ipairs({json_block(expected)}) do
  local b = __bindings[want.key]
  if not b then
    problems[#problems + 1] = want.key .. ": no binding"
  elseif b.action ~= want.action then
    problems[#problems + 1] = want.key .. ": runs " .. tostring(b.action) .. ", expected " .. want.action
  else
    local args = b.args or {{}}
    for name, value in pairs(want.args) do
      if args[name] ~= value then
        problems[#problems + 1] = want.key .. ": " .. name .. " is " .. tostring(args[name])
          .. ", expected " .. tostring(value)
      end
    end
    for name in pairs(args) do
      if want.args[name] == nil then
        problems[#problems + 1] = want.key .. ": unexpected arg " .. name
      end
    end
  end
end
if #problems > 0 then error(table.concat(problems, "; ")) end
"""
        )

    def assert_action_succeeds(self, project: str, plan: list[dict]) -> dict:
        result, trace = run_project_action(project, plan)
        self.assertEqual(0, result.returncode, f"stderr: {result.stderr}")
        self.assertEqual(expected_trace(plan), trace)
        leftovers = [
            line
            for line in result.stderr.splitlines()
            if not line.startswith(TRACE_PREFIX)
        ]
        self.assertEqual([], leftovers, result.stderr)
        return json.loads(result.stdout)

    def assert_action_fails(
        self, project: str, plan: list[dict], message: str
    ) -> None:
        result, trace = run_project_action(project, plan)
        self.assertEqual(1, result.returncode, result.stdout)
        self.assertEqual(expected_trace(plan), trace)
        self.assertEqual("", result.stdout)
        lines = result.stderr.splitlines()
        self.assertEqual(f"Error: {message}", lines[-1] if lines else "")
        self.assertTrue(
            all(line.startswith(TRACE_PREFIX) for line in lines[:-1]), result.stderr
        )

    def test_shortcuts(self) -> None:
        self.assert_bindings(
            [
                {"key": key, "action": action, "args": rest[0] if rest else {}}
                for key, action, *rest in BINDINGS
            ]
        )

    def test_project_jumps(self) -> None:
        self.assert_bindings(
            [
                {"key": key, "action": "jump_project", "args": {"project": project}}
                for key, project in PROJECT_JUMPS.items()
            ]
        )

    def test_project_jump_neighbors_preserved(self) -> None:
        self.assert_bindings(
            [
                {
                    "key": f"{PREFIX}shift+'",
                    "action": "pane.split",
                    "args": {"direction": "down"},
                },
                {"key": f"{PREFIX}p", "action": "client.tab.previous", "args": {}},
                {
                    "key": f"{PREFIX}shift+r",
                    "action": "client.config.reload",
                    "args": {},
                },
                {"key": f"{PREFIX}x", "action": "client.close", "args": {}},
                {"key": f"{PREFIX}shift+x", "action": "client.tab.close", "args": {}},
            ]
        )

    def test_resize_mode(self) -> None:
        self.assert_config_accepts(
            """
if __modes["resize"] == nil then error("the resize mode is not declared") end
if __modes["resize"].exclusive ~= true then error("the resize mode is not exclusive") end
"""
        )

    def test_config_loads_cleanly(self) -> None:
        report = config_check()
        self.assertEqual(len(BINDINGS), report["bindings"], "unexpected binding count")
        self.assertEqual(0, report["removals"], "unexpected rex.unbind call")
        actions = {action["name"]: action for action in report["actions"]}
        self.assertEqual(
            ["jump_project", "list_projects", "session_manager"],
            sorted(actions),
        )
        self.assertNotIn("args", actions["list_projects"])
        jump_args = actions["jump_project"]["args"]
        self.assertEqual(["project"], jump_args["required"])
        self.assertEqual("string", jump_args["properties"]["project"]["type"])
        manager_args = actions["session_manager"]["args"]
        self.assertEqual(["mode"], manager_args["required"])
        self.assertEqual(
            ["projects", "active", "close"],
            manager_args["properties"]["mode"]["enum"],
        )
        self.assertFalse(manager_args["additionalProperties"])
        self.assertEqual([], report["diagnostics"])

    def test_config_loads_sibling_module_from_any_cwd(self) -> None:
        """The split config resolves sessions.lua beside init.lua, not from cwd."""
        if REX is None:
            raise AssertionError("the rex CLI is not on PATH")

        with tempfile.TemporaryDirectory(prefix="rex-keymap-cwd-") as scratch:
            config = copy_config(Path(scratch))
            elsewhere = tempfile.mkdtemp(prefix="rex-keymap-elsewhere-")
            self.addCleanup(shutil.rmtree, elsewhere, True)
            result = subprocess.run(
                [REX, "config", "check", str(config), "--json"],
                capture_output=True,
                text=True,
                timeout=30,
                cwd=elsewhere,
            )

        self.assertEqual(0, result.returncode, f"stderr: {result.stderr}")
        report = json.loads(result.stdout)
        self.assertEqual(len(BINDINGS), report["bindings"])
        self.assertEqual([], report["diagnostics"])

    def test_missing_sibling_module_is_reported(self) -> None:
        """Without sessions.lua the native loader fails loudly instead of loading half a config."""
        if REX is None:
            raise AssertionError("the rex CLI is not on PATH")

        with tempfile.TemporaryDirectory(prefix="rex-keymap-missing-") as scratch:
            config = copy_config(Path(scratch), modules=())
            result = subprocess.run(
                [REX, "config", "check", str(config), "--json"],
                capture_output=True,
                text=True,
                timeout=30,
            )

        self.assertEqual(1, result.returncode, result.stdout)
        self.assertEqual("Error: the configuration has errors", result.stderr.strip())
        report = json.loads(result.stdout)
        messages = [item["message"] for item in report["diagnostics"]]
        self.assertTrue(
            any(message.startswith(f"module {SESSIONS_LUA.stem} not found") for message in messages),
            messages,
        )

    def test_missing_manager_module_is_reported(self) -> None:
        """Without session_management.lua the manager keys cannot load silently."""
        if REX is None:
            raise AssertionError("the rex CLI is not on PATH")

        with tempfile.TemporaryDirectory(prefix="rex-keymap-missing-manager-") as scratch:
            config = copy_config(Path(scratch), modules=(SESSIONS_LUA.name,))
            result = subprocess.run(
                [REX, "config", "check", str(config), "--json"],
                capture_output=True,
                text=True,
                timeout=30,
            )

        self.assertEqual(1, result.returncode, result.stdout)
        report = json.loads(result.stdout)
        messages = [item["message"] for item in report["diagnostics"]]
        self.assertTrue(
            any(
                message.startswith(
                    f"module {SESSION_MANAGEMENT_LUA.stem} not found"
                )
                for message in messages
            ),
            messages,
        )

    def test_list_projects_returns_every_sorted_preset(self) -> None:
        """The manager browses all nine presets, not only the five bound keys."""
        if REX is None:
            raise AssertionError("the rex CLI is not on PATH")

        with tempfile.TemporaryDirectory(prefix="rex-list-projects-") as scratch:
            config = copy_config(Path(scratch))
            result = subprocess.run(
                [
                    REX,
                    "--autostart=false",
                    "do",
                    str(config),
                    "--action",
                    "list_projects",
                    "--json",
                ],
                capture_output=True,
                text=True,
                timeout=30,
                env=dict(os.environ, HOME=TEST_HOME),
            )

        self.assertEqual(0, result.returncode, result.stderr)
        self.assertEqual(
            {"projects": sorted(PROJECT_TEMPLATES)}, json.loads(result.stdout)
        )
        self.assertEqual("", result.stderr)
        self.assertEqual(9, len(PROJECT_TEMPLATES))

    def test_unsupported_keys_stay_unbound(self) -> None:
        self.assert_config_accepts(
            f"""
for _, key in ipairs({json_block(UNSUPPORTED)}) do
  if __bindings[key] ~= nil then
    error(key .. " is bound to " .. tostring(__bindings[key].action)
      .. " but has no Rex client equivalent")
  end
end
"""
        )

    def test_no_global_shortcuts_beyond_prefix(self) -> None:
        self.assert_config_accepts(
            """
for key, binding in pairs(__bindings) do
  if not binding.mode then
    local root = key:match("^[^>]+")
    if root ~= "ctrl+a" then
      error("global shortcut " .. key .. " would shadow a client default")
    end
    if key:find("cmd+", 1, true) == 1 then
      error("Cmd shortcut " .. key .. " would override a client default")
    end
  end
end
"""
        )

    def test_no_tmux_navigator(self) -> None:
        report = self.assert_config_accepts(
            """
for _, binding in ipairs(rex.bindings()) do
  if binding.key == "ctrl+h" and not binding.mode then
    error("bare Ctrl+H must remain with the terminal")
  end
end
"""
        )
        self.assertEqual(
            ["jump_project", "list_projects", "session_manager"],
            sorted(action["name"] for action in report["actions"]),
            "the custom actions are the project jump and the session manager",
        )

    def test_action_reuses_labelled_session(self) -> None:
        plan = [
            {
                "kind": "call",
                "method": "session.list",
                "args": {},
                "result": {
                    "sessions": [
                        {"session_id": "session:one", "label": "sergio"},
                        {"session_id": "session:two", "label": "finaipro"},
                    ]
                },
            },
            {
                "kind": "queue",
                "method": "session.select",
                "args": {"session_id": "session:one"},
            },
        ]
        self.assertEqual(
            {"session_id": "session:one"}, self.assert_action_succeeds("sergio", plan)
        )

    def test_action_creates_missing_projects(self) -> None:
        for project, tabs in PROJECT_TEMPLATES.items():
            with self.subTest(project=project):
                session_id = f"session:created-{project}"
                self.assert_action_succeeds(
                    project,
                    [
                        {
                            "kind": "call",
                            "method": "session.list",
                            "args": {},
                            "result": {"sessions": []},
                        },
                        {
                            "kind": "call",
                            "method": "session.create",
                            "args": {
                                "label": project,
                                "initial_windows": [
                                    expected_window(tab) for tab in tabs
                                ],
                            },
                            "result": created_result(session_id, tabs),
                        },
                        {
                            "kind": "queue",
                            "method": "session.select",
                            "args": {"session_id": session_id, "window_id": "window:first"},
                        },
                    ],
                )

    def test_action_expands_home_in_template_directories(self) -> None:
        for project, tabs in PROJECT_TEMPLATES.items():
            for tab in tabs:
                cwd = expected_window(tab)["layout"]["block"]["options"]["cwd"]
                self.assertFalse(
                    cwd.startswith("~"), f"{project}: {cwd} was not expanded"
                )
                if tab["cwd"].startswith("~/"):
                    self.assertTrue(
                        cwd.startswith(f"{TEST_HOME}/"), f"{project}: {cwd}"
                    )
        notes = PROJECT_TEMPLATES["notes"][1]["cwd"]
        self.assertEqual(
            "/Users/camilo/Library/CloudStorage/OneDrive-FINAIPROTECHNOLOGIESSAS/Finaipro Web Wiki",
            notes,
            "the second notes tab keeps its absolute path",
        )

    def test_project_tabs_start_login_fish_with_startup_input(self) -> None:
        """Every tab runs interactive fish; program tabs type one command in."""
        for project, tabs in PROJECT_TEMPLATES.items():
            with self.subTest(project=project):
                session_id = f"session:created-{project}"
                result, trace = run_project_action(
                    project,
                    [
                        {
                            "kind": "call",
                            "method": "session.list",
                            "args": {},
                            "result": {"sessions": []},
                        },
                        {
                            "kind": "call",
                            "method": "session.create",
                            "args": {
                                "label": project,
                                "initial_windows": [
                                    expected_window(tab) for tab in tabs
                                ],
                            },
                            "result": created_result(session_id, tabs),
                        },
                        {
                            "kind": "queue",
                            "method": "session.select",
                            "args": {"session_id": session_id, "window_id": "window:first"},
                        },
                    ],
                )
                self.assertEqual(0, result.returncode, result.stderr)
                created = trace[1]["args"]["initial_windows"]
                self.assertEqual(len(tabs), len(created))
                for tab, window in zip(tabs, created):
                    options = window["layout"]["block"]["options"]
                    self.assertEqual(
                        [FISH_BIN, "--login", "--interactive"], options["command"]
                    )
                    self.assertNotIn("-c", options["command"])
                    self.assertEqual("none", options["shell"])
                    if "run" in tab:
                        startup = options["initial_input"]
                        self.assertEqual(tab["run"] + "\n", startup)
                        self.assertEqual(1, startup.count("\n"), startup)
                    else:
                        self.assertNotIn("initial_input", options)

    def test_action_treats_missing_session_list_as_empty(self) -> None:
        session_id = "session:created-nvim"
        self.assert_action_succeeds(
            "nvim",
            [
                {
                    "kind": "call",
                    "method": "session.list",
                    "args": {},
                    "result": {},
                },
                {
                    "kind": "call",
                    "method": "session.create",
                    "args": {
                        "label": "nvim",
                        "initial_windows": [
                            expected_window(tab) for tab in PROJECT_TEMPLATES["nvim"]
                        ],
                    },
                    "result": created_result(session_id, PROJECT_TEMPLATES["nvim"]),
                },
                {
                    "kind": "queue",
                    "method": "session.select",
                    "args": {"session_id": session_id, "window_id": "window:first"},
                },
            ],
        )

    def test_action_unknown_project(self) -> None:
        self.assert_action_fails("nonexistent", [], "unknown project: nonexistent")

    def test_action_list_failure(self) -> None:
        plan = [
            {
                "kind": "call",
                "method": "session.list",
                "args": {},
                "error": "conflict",
            }
        ]
        self.assert_action_fails("nvim", plan, "session.list failed: conflict")

    def test_action_create_failure(self) -> None:
        plan = [
            {
                "kind": "call",
                "method": "session.list",
                "args": {},
                "result": {"sessions": []},
            },
            {
                "kind": "call",
                "method": "session.create",
                "args": {
                    "label": "sql-finaipro",
                    "initial_windows": [
                        expected_window(tab)
                        for tab in PROJECT_TEMPLATES["sql-finaipro"]
                    ],
                },
                "error": "conflict",
            },
        ]
        self.assert_action_fails(
            "sql-finaipro", plan, "session.create failed: conflict"
        )

    def test_action_duplicate_labels(self) -> None:
        plan = [
            {
                "kind": "call",
                "method": "session.list",
                "args": {},
                "result": {
                    "sessions": [
                        {"session_id": "session:a", "label": "centai"},
                        {"session_id": "session:b", "label": "centai"},
                    ]
                },
            }
        ]
        self.assert_action_fails(
            "centai", plan, "more than one session is labelled centai"
        )


if __name__ == "__main__":
    unittest.main(verbosity=2)
