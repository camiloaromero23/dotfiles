#!/usr/bin/env python3
"""Regression tests for the fzf session manager and its terminal helper.

The Lua action is exercised through ``rex do --action`` on a temporary copy of
the real configuration. A temporary ``rex.action`` wrapper, installed before
``init.lua`` loads, captures the callback that ``session_management.setup``
registers. ``rex.call`` and ``rex.session.new_layer`` are replaced by recording
stubs, so the action never reaches the server or opens a layer. The captured
callback receives a fake client/session context, which keeps the tests
deterministic without a live app and without a production export.

The Bash helper runs as a subprocess. Fake ``fzf`` and ``rex`` executables
record the public command lines and answer with fixed JSON, so no real session
is listed, selected, or killed. Selection rows are checked through fzf's stdin,
never through the helper's private state. A PTY test pins the interactive
acknowledgement path without touching a Rex session.
"""

from __future__ import annotations

import json
import os
import pty
import select
import shutil
import subprocess
import sys
import tempfile
import time
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from test_keymaps import (  # noqa: E402 - the test directory is added above
    ACTION_STUBS,
    CONFIG_DIR,
    FLAVOR,
    REX,
    TEST_HOME,
    TRACE_PREFIX,
    copy_config,
    expected_trace,
    json_block,
)

HELPER = CONFIG_DIR / "session_management.sh"
REAL_JQ = shutil.which("jq") or "/opt/homebrew/bin/jq"
CLIENT = "client:01a15ecf-5fdc-7105-8a25-f5706da94c74"
SERVER = "unix:/tmp/rex-session-manager-test.sock"

# Replace rex.action before init.lua loads so the test can capture the callback
# registered by session_management.setup. The module itself exposes only setup.
MANAGER_CAPTURE = """
local __captured_actions = {}
local __original_action = rex.action
rex.action = function(spec)
  if spec.name == "session_manager" then
    __captured_actions.session_manager = spec.run
  end
  return __original_action(spec)
end
"""

MANAGER_STUBS = """
local __module = require("session_management")
if __module.run ~= nil then
  error("session_management must expose only setup", 0)
end
local __manager = __captured_actions.session_manager
if __manager == nil then
  error("session_manager action was not registered", 0)
end
rex.action = __original_action
rex.session.new_layer = function(args)
  __record(__expect("layer"), "session.new_layer", args)
  local step = __plan[__index]
  if step.error ~= nil then return nil, step.error end
  return step.result
end
rex.action{
  name = "__test_session_manager",
  title = "Test Session Manager",
  args = {
    mode = "string",
    client_id = "string?",
    session_id = "string?",
    block_id = "string?",
  },
  run = function(_, args)
    local ctx = { origin = "key" }
    if args.client_id ~= nil then ctx.client_id = args.client_id end
    if args.session_id ~= nil then ctx.session_id = args.session_id end
    if args.block_id ~= nil then ctx.block_id = args.block_id end
    return __manager(ctx, { mode = args.mode })
  end,
}
"""


def keymap_step(scratch: Path) -> dict:
    return {
        "kind": "call",
        "method": "client.keymap",
        "args": {},
        "result": {"config": {"path": str(scratch / "init.lua")}},
    }


def layer_step(
    scratch: Path,
    mode: str,
    *,
    client_id: str = CLIENT,
    session_id: str = "session:test",
    error: str | None = None,
) -> dict:
    step = {
        "kind": "layer",
        "method": "session.new_layer",
        "args": {
            "session_id": session_id,
            "bounds": [0, 0, 1, 1],
            "focus": True,
            "layout": {
                "block": {
                    "flavor": FLAVOR,
                    "options": {
                        "shell": "none",
                        "command": [
                            "/bin/bash",
                            str(scratch / HELPER.name),
                            mode,
                            client_id,
                        ],
                        "exit": {"on_completion": True},
                    },
                }
            },
        },
        "result": {
            "layer_id": "layer:test",
            "block_ids": ["block:test"],
            "revision": 7,
        },
    }
    if error is not None:
        step["error"] = error
    return step


def run_manager(
    args: dict, steps: list[dict | object], *, copy_helper: bool = True
) -> tuple[subprocess.CompletedProcess, list[dict], list[dict]]:
    """Run the real manager action with recording API stubs."""
    if REX is None:
        raise AssertionError("the rex CLI is not on PATH")

    with tempfile.TemporaryDirectory(prefix="rex manager ") as raw:
        scratch = Path(raw)
        plan = [step(scratch) if callable(step) else step for step in steps]
        stubs = ACTION_STUBS.replace("__plan__", json_block(plan)) + MANAGER_STUBS
        config = copy_config(
            scratch,
            f"\n{stubs}\n",
            copy_helper=copy_helper,
            prefix=MANAGER_CAPTURE,
        )
        result = subprocess.run(
            [
                REX,
                "--autostart=false",
                "do",
                str(config),
                "--action",
                "__test_session_manager",
                "--args",
                json.dumps(args),
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
    return result, trace, plan


class ManagerActionTest(unittest.TestCase):
    def assert_succeeds(self, args: dict, steps: list, expected: dict) -> None:
        result, trace, plan = run_manager(args, steps)
        self.assertEqual(0, result.returncode, f"stderr: {result.stderr}")
        self.assertEqual(expected_trace(plan), trace)
        self.assertEqual(expected, json.loads(result.stdout))
        leftovers = [
            line for line in result.stderr.splitlines() if not line.startswith(TRACE_PREFIX)
        ]
        self.assertEqual([], leftovers, result.stderr)

    def assert_fails(self, args: dict, steps: list, message: str, **kwargs) -> None:
        result, trace, plan = run_manager(args, steps, **kwargs)
        self.assertEqual(1, result.returncode, result.stdout)
        self.assertEqual(expected_trace(plan), trace)
        self.assertEqual("", result.stdout)
        lines = result.stderr.splitlines()
        self.assertEqual(f"Error: {message}", lines[-1] if lines else "")
        self.assertTrue(
            all(line.startswith(TRACE_PREFIX) for line in lines[:-1]), result.stderr
        )

    def context(self, mode: str) -> dict:
        return {"mode": mode, "client_id": CLIENT, "session_id": "session:test"}

    def test_each_mode_opens_a_floating_terminal(self) -> None:
        for mode in ("projects", "active", "close"):
            with self.subTest(mode=mode):
                self.assert_succeeds(
                    self.context(mode),
                    [keymap_step, lambda scratch, mode=mode: layer_step(scratch, mode)],
                    {
                        "layer_id": "layer:test",
                        "block_ids": ["block:test"],
                    },
                )

    def test_missing_client_fails_before_the_picker(self) -> None:
        self.assert_fails(
            {"mode": "projects", "session_id": "session:test"},
            [],
            "session_manager needs the invoking client; run it from a Rex shortcut or pass -C",
        )

    def test_missing_session_fails_before_the_picker(self) -> None:
        self.assert_fails(
            {"mode": "projects", "client_id": CLIENT},
            [],
            "session_manager needs the invoking session",
        )

    def test_unknown_mode_fails_before_the_picker(self) -> None:
        self.assert_fails(
            self.context("browse"),
            [],
            "unknown session manager mode: browse",
        )

    def test_keymap_failure_is_reported(self) -> None:
        self.assert_fails(
            self.context("projects"),
            [
                {
                    "kind": "call",
                    "method": "client.keymap",
                    "args": {},
                    "error": "conflict",
                }
            ],
            "client.keymap failed: conflict",
        )

    def test_missing_config_path_is_reported(self) -> None:
        self.assert_fails(
            self.context("projects"),
            [
                {
                    "kind": "call",
                    "method": "client.keymap",
                    "args": {},
                    "result": {"config": {}},
                }
            ],
            "client.keymap returned no configuration path",
        )

    def test_missing_helper_fails_before_the_terminal(self) -> None:
        if REX is None:
            raise AssertionError("the rex CLI is not on PATH")

        captured: dict[str, Path] = {}

        def capture(scratch: Path) -> dict:
            captured["helper"] = scratch / HELPER.name
            return keymap_step(scratch)

        result, trace, plan = run_manager(
            self.context("close"),
            [capture],
            copy_helper=False,
        )

        self.assertEqual(1, result.returncode, result.stdout)
        self.assertEqual(expected_trace(plan), trace)
        self.assertEqual("", result.stdout)
        self.assertEqual(
            f"Error: session manager helper is missing or unreadable: {captured['helper']}",
            result.stderr.splitlines()[-1],
        )

    def test_new_layer_failure_is_reported(self) -> None:
        self.assert_fails(
            self.context("active"),
            [
                keymap_step,
                lambda scratch: layer_step(scratch, "active", error="not_found"),
            ],
            "session.new_layer failed: not_found",
        )


FAKE_FZF = """#!/usr/bin/env python3
import json
import os
import sys

data = sys.stdin.read()
log = os.environ.get("FAKE_FZF_LOG")
if log:
    with open(log, "a", encoding="utf-8") as handle:
        handle.write(json.dumps({"argv": sys.argv[1:], "stdin": data,
                                 "default_opts": os.environ.get("FZF_DEFAULT_OPTS"),
                                 "opts_file": os.environ.get("FZF_DEFAULT_OPTS_FILE")}) + "\\n")

mode = os.environ.get("FAKE_FZF_MODE", "select-first")
lines = data.splitlines()
if mode == "cancel":
    sys.exit(130)
if mode == "no-match":
    sys.exit(1)
if mode == "error":
    sys.stderr.write("fzf: failed to read input\\n")
    sys.exit(2)
if mode == "empty":
    sys.exit(0)
if mode == "raw":
    sys.stdout.write(os.environ["FAKE_FZF_RAW"] + "\\n")
    sys.exit(0)
if lines:
    sys.stdout.write(lines[int(os.environ.get("FAKE_FZF_INDEX", "0"))] + "\\n")
sys.exit(0)
"""

FAKE_REX = """#!/usr/bin/env python3
import json
import os
import sys

argv = sys.argv[1:]
log = os.environ.get("FAKE_REX_LOG")
if log:
    with open(log, "a", encoding="utf-8") as handle:
        handle.write(json.dumps(argv) + "\\n")


def fail(message, code=1):
    sys.stderr.write(message + "\\n")
    sys.exit(code)


if not os.environ.get("REX_SERVER"):
    fail("fake rex: REX_SERVER missing")
if "--autostart=false" not in argv:
    fail("fake rex: --autostart=false missing")
try:
    server = argv[argv.index("--server") + 1]
except (ValueError, IndexError):
    fail("fake rex: --server missing")
if server != os.environ["REX_SERVER"]:
    fail("fake rex: unexpected server " + server)
if any(name in argv for name in ("jump_project", "session.select")) and "-C" not in argv:
    fail("fake rex: client operation without -C")


def finish(prefix):
    stderr = os.environ.get(prefix + "_STDERR")
    if stderr:
        sys.stderr.write(stderr + "\\n")
    sys.exit(int(os.environ.get(prefix + "_EXIT", "0")))


if "do" in argv and "list_projects" in argv:
    print(os.environ.get("FAKE_PROJECTS_JSON", '{"projects":[]}'))
    finish("FAKE_LIST_PROJECTS")
if "ls" in argv and "--json" in argv:
    print(os.environ.get("FAKE_SESSIONS_JSON", '{"sessions":[]}'))
    finish("FAKE_LS")
if "do" in argv and "jump_project" in argv:
    print('{"session_id":"session:jumped"}')
    finish("FAKE_JUMP")
if "do" in argv and "session.select" in argv:
    print('{"revision":1}')
    finish("FAKE_SELECT")
if "kill" in argv:
    print('{"revision":2}')
    finish("FAKE_KILL")
fail("fake rex: unexpected command: " + " ".join(argv))
"""

BASE = ["--autostart=false", "--server", SERVER]


class HelperTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory(prefix="rex manager helper ")
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)
        self.fzf_bin = self.write_executable("fzf", FAKE_FZF)
        self.rex_bin = self.write_executable("rex", FAKE_REX)
        self.fzf_log = self.directory / "fzf.log"
        self.rex_log = self.directory / "rex.log"

    def write_executable(self, name: str, content: str) -> Path:
        path = self.directory / name
        path.write_text(content, encoding="utf-8")
        path.chmod(0o755)
        return path

    def environment(self, **overrides: str | None) -> dict[str, str]:
        environment = {
            "PATH": os.environ.get("PATH", ""),
            "HOME": TEST_HOME,
            "REX_SERVER": SERVER,
            "FZF_BIN": str(self.fzf_bin),
            "JQ_BIN": REAL_JQ,
            "REX_BIN": str(self.rex_bin),
            "FAKE_FZF_LOG": str(self.fzf_log),
            "FAKE_REX_LOG": str(self.rex_log),
            "FAKE_PROJECTS_JSON": json.dumps(
                {"projects": ["centai", "dotfiles", "finaipro"]}
            ),
            "FAKE_SESSIONS_JSON": json.dumps(
                {"sessions": [{"session_id": "session:aaaaaaaaaaaa", "label": "notes"}]}
            ),
        }
        for key, value in overrides.items():
            if value is None:
                environment.pop(key, None)
            else:
                environment[key] = value
        return environment

    def run_helper(
        self, args: list[str], stdin: str = "", **overrides: str | None
    ) -> subprocess.CompletedProcess:
        return subprocess.run(
            ["/bin/bash", str(HELPER), *args],
            input=stdin,
            capture_output=True,
            text=True,
            timeout=30,
            env=self.environment(**overrides),
        )

    def rex_calls(self) -> list[list[str]]:
        if not self.rex_log.exists():
            return []
        return [
            json.loads(line) for line in self.rex_log.read_text(encoding="utf-8").splitlines()
        ]

    def fzf_calls(self) -> list[dict]:
        if not self.fzf_log.exists():
            return []
        return [
            json.loads(line)
            for line in self.fzf_log.read_text(encoding="utf-8").splitlines()
        ]

    def test_fzf_has_mocha_colors_without_shell_defaults(self) -> None:
        result = self.run_helper(
            ["projects", CLIENT], FAKE_FZF_MODE="cancel",
            FZF_DEFAULT_OPTS=None, FZF_DEFAULT_OPTS_FILE=None,
        )
        self.assertEqual((0, "", ""), (result.returncode, result.stdout, result.stderr))
        options = self.fzf_calls()[0]["default_opts"]
        self.assertIsInstance(options, str)
        for color in ("bg:#1E1E2E", "fg:#CDD6F4", "border:#6C7086"):
            self.assertIn(color, options)
        self.assertEqual([BASE + ["do", "list_projects", "--json"]], self.rex_calls())

    def test_fzf_preserves_supplied_defaults(self) -> None:
        options = "--color=bg:#112233,fg:#abcdef"
        result = self.run_helper(
            ["projects", CLIENT], FAKE_FZF_MODE="cancel", FZF_DEFAULT_OPTS=options,
        )
        self.assertEqual((0, "", ""), (result.returncode, result.stdout, result.stderr))
        self.assertEqual(options, self.fzf_calls()[0]["default_opts"])
        self.assertEqual([BASE + ["do", "list_projects", "--json"]], self.rex_calls())

    def test_fzf_preserves_options_file_without_injecting_a_theme(self) -> None:
        options_file = self.directory / "fzf options"
        options_file.write_text("--color=bg:#112233", encoding="utf-8")
        result = self.run_helper(
            ["projects", CLIENT], FAKE_FZF_MODE="cancel",
            FZF_DEFAULT_OPTS=None, FZF_DEFAULT_OPTS_FILE=str(options_file),
        )
        self.assertEqual((0, "", ""), (result.returncode, result.stdout, result.stderr))
        call = self.fzf_calls()[0]
        self.assertIsNone(call["default_opts"])
        self.assertEqual(str(options_file), call["opts_file"])
        self.assertEqual([BASE + ["do", "list_projects", "--json"]], self.rex_calls())

    def test_picker_fills_float_despite_inherited_geometry(self) -> None:
        defaults = "--height=40% --margin=2 --padding=1 --color=bg:#1E1E2E"
        for mode in ("projects", "active", "close"):
            with self.subTest(mode=mode):
                self.rex_log.unlink(missing_ok=True)
                self.fzf_log.unlink(missing_ok=True)
                result = self.run_helper(
                    [mode, CLIENT], FAKE_FZF_MODE="cancel", FZF_DEFAULT_OPTS=defaults,
                )
                self.assertEqual((0, "", ""), (result.returncode, result.stdout, result.stderr))
                call = self.fzf_calls()[0]
                self.assertEqual(defaults, call["default_opts"])
                for argument in ("--no-height", "--margin=0", "--padding=0"):
                    self.assertIn(argument, call["argv"])
                expected = ["do", "list_projects", "--json"] if mode == "projects" else ["ls", "--json"]
                self.assertEqual([BASE + expected], self.rex_calls())

    def test_picker_presentation_matches_kitty(self) -> None:
        modes = {
            "projects": ("rex-session-manager", "1.."),
            "active": ("rex-session-manager (active-sessions)", "2.."),
            "close": ("rex-session-manager (kill-session)", "2.."),
        }
        for mode, (title, fields) in modes.items():
            with self.subTest(mode=mode):
                self.rex_log.unlink(missing_ok=True)
                self.fzf_log.unlink(missing_ok=True)
                result = self.run_helper([mode, CLIENT], FAKE_FZF_MODE="cancel")
                self.assertEqual((0, "", ""), (result.returncode, result.stdout, result.stderr))
                argv = self.fzf_calls()[0]["argv"]
                for argument in ("--prompt=> ", "--border=rounded",
                                 "--border-label=" + title, "--no-multi",
                                 "--no-clear", "--with-nth=" + fields):
                    self.assertIn(argument, argv)
                for argument in ("--height=100%", "--reverse", "--no-info"):
                    self.assertNotIn(argument, argv)
                self.assertFalse(any(argument.startswith("--header") for argument in argv))
                expected = ["do", "list_projects", "--json"] if mode == "projects" else ["ls", "--json"]
                self.assertEqual([BASE + expected], self.rex_calls())

    def test_projects_switches_with_exact_project_json(self) -> None:
        result = self.run_helper(["projects", CLIENT])

        self.assertEqual(0, result.returncode, result.stderr)
        self.assertEqual("", result.stdout)
        self.assertEqual("", result.stderr)
        self.assertEqual(
            [
                BASE + ["do", "list_projects", "--json"],
                BASE
                + [
                    "-C",
                    CLIENT,
                    "do",
                    "jump_project",
                    "--args",
                    '{"project":"centai"}',
                    "--json",
                ],
            ],
            self.rex_calls(),
        )
        fzf = self.fzf_calls()[0]
        self.assertEqual("centai\ndotfiles\nfinaipro\n", fzf["stdin"])
        for argument in ("--prompt=> ", "--with-nth=1..", "--border=rounded", "--no-multi"):
            self.assertIn(argument, fzf["argv"])

    def test_projects_cancel_and_no_match_are_noops(self) -> None:
        for mode in ("cancel", "no-match"):
            with self.subTest(mode=mode):
                self.rex_log.unlink(missing_ok=True)
                self.fzf_log.unlink(missing_ok=True)
                result = self.run_helper(["projects", CLIENT], FAKE_FZF_MODE=mode)
                self.assertEqual(0, result.returncode, result.stderr)
                self.assertEqual("", result.stdout)
                self.assertEqual("", result.stderr)
                self.assertEqual(
                    [BASE + ["do", "list_projects", "--json"]], self.rex_calls()
                )

    def test_projects_fzf_error_is_propagated(self) -> None:
        result = self.run_helper(["projects", CLIENT], FAKE_FZF_MODE="error")

        self.assertEqual(2, result.returncode)
        self.assertEqual("", result.stdout)
        self.assertEqual(
            "fzf: failed to read input\nError: fzf failed with exit 2\n",
            result.stderr,
        )
        self.assertEqual([BASE + ["do", "list_projects", "--json"]], self.rex_calls())

    def test_projects_backend_failure_is_propagated(self) -> None:
        result = self.run_helper(
            ["projects", CLIENT],
            FAKE_LIST_PROJECTS_EXIT="7",
            FAKE_LIST_PROJECTS_STDERR="Error: no configuration action",
        )

        self.assertEqual(7, result.returncode)
        self.assertEqual("", result.stdout)
        self.assertEqual("Error: no configuration action\n", result.stderr)
        self.assertEqual([], self.fzf_calls())
        self.assertEqual([BASE + ["do", "list_projects", "--json"]], self.rex_calls())

    def test_projects_invalid_selection_is_rejected(self) -> None:
        result = self.run_helper(
            ["projects", CLIENT],
            FAKE_FZF_MODE="raw",
            FAKE_FZF_RAW="not-a-project",
        )

        self.assertEqual(1, result.returncode)
        self.assertEqual("", result.stdout)
        self.assertEqual(
            "Error: the selection is not one of the listed projects\n", result.stderr
        )
        self.assertEqual([BASE + ["do", "list_projects", "--json"]], self.rex_calls())

    def test_empty_project_registry_is_a_noop(self) -> None:
        result = self.run_helper(
            ["projects", CLIENT], FAKE_PROJECTS_JSON='{"projects":[]}'
        )

        self.assertEqual(0, result.returncode, result.stderr)
        self.assertEqual("", result.stdout)
        self.assertEqual("", result.stderr)
        self.assertEqual([], self.fzf_calls())

    def test_active_switches_by_hidden_session_id(self) -> None:
        sessions = [
            {"session_id": "session:01a15ebd-b25a-735b-111111", "label": "dotfiles"},
            {"session_id": "session:01a160f3-f994-7b94-111111", "label": "dotfiles"},
            {
                "session_id": "session:cccccccccccc",
                "label": "evil\t$(rm -rf ~)\nnext",
            },
        ]
        result = self.run_helper(
            ["active", CLIENT],
            FAKE_SESSIONS_JSON=json.dumps({"sessions": sessions}),
            FAKE_FZF_INDEX="1",
        )

        self.assertEqual(0, result.returncode, result.stderr)
        self.assertEqual("", result.stdout)
        self.assertEqual("", result.stderr)
        self.assertEqual(
            [
                BASE + ["ls", "--json"],
                BASE
                + [
                    "-C",
                    CLIENT,
                    "do",
                    "session.select",
                    "session_id=session:01a160f3-f994-7b94-111111",
                ],
            ],
            self.rex_calls(),
        )

        rows = self.fzf_calls()[0]["stdin"].splitlines()
        self.assertEqual(3, len(rows))
        fields = [row.split("\t") for row in rows]
        self.assertTrue(all(len(row) == 2 for row in fields), fields)
        self.assertEqual(
            [
                "session:01a15ebd-b25a-735b-111111",
                "session:01a160f3-f994-7b94-111111",
                "session:cccccccccccc",
            ],
            [row[0] for row in fields],
        )
        self.assertEqual(
            "dotfiles [session:01a15ebd-b25a-735b-111111]", fields[0][1]
        )
        self.assertEqual(
            "dotfiles [session:01a160f3-f994-7b94-111111]", fields[1][1]
        )
        self.assertEqual("evil?$(rm -rf ~)?next", fields[2][1])
        for call in self.rex_calls():
            self.assertNotIn("evil", " ".join(call))

    def test_active_cancel_and_empty_list_are_noops(self) -> None:
        result = self.run_helper(["active", CLIENT], FAKE_FZF_MODE="cancel")
        self.assertEqual(0, result.returncode, result.stderr)
        self.assertEqual("", result.stdout)
        self.assertEqual("", result.stderr)
        self.assertEqual([BASE + ["ls", "--json"]], self.rex_calls())

        self.rex_log.unlink()
        self.fzf_log.unlink(missing_ok=True)
        result = self.run_helper(
            ["active", CLIENT], FAKE_SESSIONS_JSON='{"sessions":[]}'
        )
        self.assertEqual(0, result.returncode, result.stderr)
        self.assertEqual("", result.stdout)
        self.assertEqual("", result.stderr)
        self.assertEqual([], self.fzf_calls())

    def test_active_fzf_error_is_propagated(self) -> None:
        result = self.run_helper(["active", CLIENT], FAKE_FZF_MODE="error")

        self.assertEqual(2, result.returncode)
        self.assertEqual("", result.stdout)
        self.assertEqual(
            "fzf: failed to read input\nError: fzf failed with exit 2\n",
            result.stderr,
        )
        self.assertEqual([BASE + ["ls", "--json"]], self.rex_calls())

    def test_active_empty_selection_is_rejected(self) -> None:
        result = self.run_helper(["active", CLIENT], FAKE_FZF_MODE="empty")

        self.assertEqual(1, result.returncode)
        self.assertEqual("", result.stdout)
        self.assertEqual("Error: fzf returned an empty selection\n", result.stderr)
        self.assertEqual([BASE + ["ls", "--json"]], self.rex_calls())

    def test_active_invalid_selection_is_rejected(self) -> None:
        result = self.run_helper(
            ["active", CLIENT],
            FAKE_FZF_MODE="raw",
            FAKE_FZF_RAW="session:not-listed\tfake",
        )

        self.assertEqual(1, result.returncode)
        self.assertEqual("", result.stdout)
        self.assertEqual(
            "Error: the selection is not one of the listed sessions\n", result.stderr
        )
        self.assertEqual([BASE + ["ls", "--json"]], self.rex_calls())

    def test_close_exact_y_kills_the_selected_id(self) -> None:
        result = self.run_helper(["close", CLIENT], stdin="y\n")

        self.assertEqual(0, result.returncode, result.stderr)
        self.assertEqual("Close session notes (session:aaaaaaaaaaaa)? [y/N] ", result.stdout)
        self.assertEqual("", result.stderr)
        self.assertEqual(
            [
                BASE + ["ls", "--json"],
                BASE + ["kill", "session:aaaaaaaaaaaa"],
            ],
            self.rex_calls(),
        )

    def test_close_negative_and_escape_confirmations_keep_the_session(self) -> None:
        for answer in ("\n", "yes\n", "\x1b\n", "Y\n"):
            with self.subTest(answer=repr(answer)):
                self.rex_log.unlink(missing_ok=True)
                result = self.run_helper(["close", CLIENT], stdin=answer)
                self.assertEqual(0, result.returncode, result.stderr)
                self.assertEqual(
                    "Close session notes (session:aaaaaaaaaaaa)? [y/N] "
                    "Keeping session notes.\n",
                    result.stdout,
                )
                self.assertEqual("", result.stderr)
                self.assertEqual([BASE + ["ls", "--json"]], self.rex_calls())

    def test_close_cancel_is_a_noop(self) -> None:
        result = self.run_helper(["close", CLIENT], FAKE_FZF_MODE="cancel")

        self.assertEqual(0, result.returncode, result.stderr)
        self.assertEqual("", result.stdout)
        self.assertEqual("", result.stderr)
        self.assertEqual([BASE + ["ls", "--json"]], self.rex_calls())

    def test_close_selected_missing_session_does_not_fall_back(self) -> None:
        result = self.run_helper(
            ["close", CLIENT],
            stdin="y\n",
            FAKE_KILL_EXIT="1",
            FAKE_KILL_STDERR="Error: session not found: session:aaaaaaaaaaaa",
        )

        self.assertEqual(1, result.returncode)
        self.assertEqual("Close session notes (session:aaaaaaaaaaaa)? [y/N] ", result.stdout)
        self.assertEqual(
            "Error: session not found: session:aaaaaaaaaaaa\n", result.stderr
        )
        self.assertEqual(
            [
                BASE + ["ls", "--json"],
                BASE + ["kill", "session:aaaaaaaaaaaa"],
            ],
            self.rex_calls(),
        )

    def test_close_invalid_selection_is_rejected(self) -> None:
        result = self.run_helper(
            ["close", CLIENT],
            stdin="y\n",
            FAKE_FZF_MODE="raw",
            FAKE_FZF_RAW="session:not-listed\tfake",
        )

        self.assertEqual(1, result.returncode)
        self.assertEqual("", result.stdout)
        self.assertEqual(
            "Error: the selection is not one of the listed sessions\n", result.stderr
        )
        self.assertEqual([BASE + ["ls", "--json"]], self.rex_calls())

    def test_missing_server_is_rejected(self) -> None:
        result = self.run_helper(["projects", CLIENT], REX_SERVER=None)

        self.assertEqual(1, result.returncode)
        self.assertEqual("", result.stdout)
        self.assertEqual(
            "Error: REX_SERVER is not set; run this manager from a Rex terminal\n",
            result.stderr,
        )
        self.assertEqual([], self.rex_calls())
        self.assertEqual([], self.fzf_calls())

    def test_missing_or_empty_client_is_rejected(self) -> None:
        result = self.run_helper(["projects"])
        self.assertEqual(2, result.returncode)
        self.assertEqual("", result.stdout)
        self.assertTrue(
            result.stderr.startswith("Error: expected MODE and CLIENT_ID\nUsage: "),
            result.stderr,
        )

        result = self.run_helper(["projects", ""])
        self.assertEqual(2, result.returncode)
        self.assertEqual("", result.stdout)
        self.assertTrue(
            result.stderr.startswith("Error: CLIENT_ID must not be empty\nUsage: "),
            result.stderr,
        )
        self.assertEqual([], self.rex_calls())

    def test_invalid_mode_is_rejected(self) -> None:
        result = self.run_helper(["bogus", CLIENT])

        self.assertEqual(2, result.returncode)
        self.assertEqual("", result.stdout)
        self.assertTrue(
            result.stderr.startswith("Error: unknown mode: bogus\nUsage: "),
            result.stderr,
        )
        self.assertEqual([], self.rex_calls())

    def test_missing_dependencies_are_rejected(self) -> None:
        cases = [
            ("FZF_BIN", "/nonexistent/fzf", "fzf"),
            ("JQ_BIN", "/nonexistent/jq", "jq"),
            ("REX_BIN", "/nonexistent/rex", "rex"),
        ]
        for variable, path, label in cases:
            with self.subTest(variable=variable):
                result = self.run_helper(["projects", CLIENT], **{variable: path})
                self.assertEqual(1, result.returncode)
                self.assertEqual("", result.stdout)
                self.assertEqual(
                    f"Error: {label} is not executable: {path}\n", result.stderr
                )
                self.assertEqual([], self.rex_calls())
                self.assertEqual([], self.fzf_calls())

    def run_helper_pty(
        self, args: list[str], **overrides: str | None
    ) -> tuple[int, subprocess.Popen]:
        """Run the helper with a real TTY on stdin, stdout, and stderr."""
        master, slave = pty.openpty()
        process = subprocess.Popen(
            ["/bin/bash", str(HELPER), *args],
            stdin=slave,
            stdout=slave,
            stderr=slave,
            close_fds=True,
            env=self.environment(**overrides),
        )
        os.close(slave)
        return master, process

    def test_interactive_error_waits_for_enter_before_exit(self) -> None:
        """A non-TTY caller gets no prompt; a real terminal gets an ack wait."""
        master, process = self.run_helper_pty(
            ["active", CLIENT],
            FAKE_LS_EXIT="1",
            FAKE_LS_STDERR="Error: backend unavailable",
        )
        marker = b"Press Enter to close."
        output = b""
        try:
            deadline = time.monotonic() + 10
            while marker not in output:
                remaining = deadline - time.monotonic()
                if remaining <= 0:
                    self.fail(f"helper did not ask for acknowledgement: {output!r}")
                ready, _, _ = select.select([master], [], [], remaining)
                if not ready:
                    self.fail(f"helper did not ask for acknowledgement: {output!r}")
                try:
                    chunk = os.read(master, 4096)
                except OSError:
                    break
                if not chunk:
                    break
                output += chunk

            self.assertIn(b"Error: backend unavailable", output)
            self.assertIn(marker, output)
            self.assertIsNone(
                process.poll(), "the helper exited before the acknowledgement"
            )

            os.write(master, b"\n")
            self.assertEqual(1, process.wait(timeout=10))
            self.assertEqual([BASE + ["ls", "--json"]], self.rex_calls())
        finally:
            if process.poll() is None:
                process.kill()
                process.wait(timeout=10)
            os.close(master)


if __name__ == "__main__":
    unittest.main(verbosity=2)
