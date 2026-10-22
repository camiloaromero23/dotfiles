#!/bin/bash
#
# fzf menus for the Rex session manager. session_management.lua starts this
# script in a temporary floating terminal, so fzf has a real TTY.
#
# Usage: session_management.sh MODE CLIENT_ID
#
#   projects  switch to a configured project through the jump_project action
#   active    switch to a running session by its full session ID
#   close     close a running session after an explicit y confirmation
#
# The script always uses the inherited REX_SERVER and the client that pressed
# the key, so a menu cannot drift to another server or app. It never evaluates
# labels or reads Rex files directly: labels are display data, and every action
# goes through the public CLI.
#
# Exit status: 0 for success or cancellation, 2 for bad arguments, 1 for a
# dependency or backend failure, and the backend's own status when it fails.
# On a real terminal, a nonzero exit prints "Press Enter to close." and waits,
# because Rex owns the popup lifecycle and may close a quick exit before a later
# error is read. Non-TTY callers keep their exact output and status without the
# prompt.

set -u

acknowledge_error() {
  local status=$?
  trap - EXIT
  if [ "$status" -ne 0 ] && [ -t 0 ] && [ -t 1 ]; then
    printf 'Press Enter to close.'
    IFS= read -r _ || true
  fi
  exit "$status"
}

trap acknowledge_error EXIT

usage() {
  printf 'Usage: %s MODE CLIENT_ID\n' "${0##*/}" >&2
  printf '  MODE: projects | active | close\n' >&2
}

fail() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

if [ "$#" -ne 2 ]; then
  printf 'Error: expected MODE and CLIENT_ID\n' >&2
  usage
  exit 2
fi

mode=$1
client_id=$2

case "$mode" in
  projects | active | close) ;;
  *)
    printf 'Error: unknown mode: %s\n' "$mode" >&2
    usage
    exit 2
    ;;
esac

if [ -z "$client_id" ]; then
  printf 'Error: CLIENT_ID must not be empty\n' >&2
  usage
  exit 2
fi

if [ -z "${REX_SERVER:-}" ]; then
  fail "REX_SERVER is not set; run this manager from a Rex terminal"
fi

FZF_BIN=${FZF_BIN:-/opt/homebrew/bin/fzf}
JQ_BIN=${JQ_BIN:-/opt/homebrew/bin/jq}
REX_BIN=${REX_BIN:-rex}

# GUI-launched Rex may not inherit fish's exported fzf theme. Match the
# Catppuccin Mocha colors in fish/config.fish only when no defaults are supplied.
if [ -z "${FZF_DEFAULT_OPTS:-}" ] && [ -z "${FZF_DEFAULT_OPTS_FILE:-}" ]; then
  FZF_DEFAULT_OPTS='
    --color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8
    --color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC
    --color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8
    --color=selected-bg:#45475A
    --color=border:#6C7086,label:#CDD6F4
  '
  export FZF_DEFAULT_OPTS
fi

check_bin() {
  local label=$1
  local path=$2
  if ! command -v "$path" >/dev/null 2>&1; then
    fail "$label is not executable: $path"
  fi
}

check_bin fzf "$FZF_BIN"
check_bin jq "$JQ_BIN"
check_bin rex "$REX_BIN"

# The menu always names its client explicitly; an ambient REX_CLIENT must not
# decide which app receives a switch.
unset REX_CLIENT

REX_BASE=("$REX_BIN" --autostart=false --server "$REX_SERVER")
REX_C=("${REX_BASE[@]}" -C "$client_id")

# Show a hidden full ID first and the label second. @tsv escapes tabs, newlines,
# and backslashes, so a label cannot become a second row or a spare field.
SESSION_ROWS_FILTER='
def safe: tostring | gsub("[[:cntrl:]]"; "?");
(.sessions // []) as $sessions
| ($sessions
   | map(.label // "" | safe)
   | group_by(.)
   | map({ key: .[0], value: length })
   | from_entries) as $counts
| $sessions[]
| . as $session
| ($session.label // "" | safe) as $label
| [
    (($session.session_id // "") | tostring),
    ((if $label == "" then "(unlabelled)" else $label end)
      + (if ($counts[$label] // 0) > 1
         then " [" + (($session.session_id // "") | tostring) + "]"
         else "" end))
  ]
| @tsv'

# Run fzf over rows already produced from trusted JSON. Session rows keep the
# ID in field one and hide it from the display; project rows are single names.
# Rex sizes the floating terminal; keep fzf fullscreen with no extra spacing.
choose() {
  local rows=$1
  local prompt=$2
  local border_label=$3
  local fields=$4
  local status
  SELECTED=$(printf '%s\n' "$rows" | "$FZF_BIN" \
    --delimiter=$'\t' \
    --with-nth="$fields" \
    --prompt="$prompt" \
    --no-height \
    --margin=0 \
    --padding=0 \
    --border=rounded \
    --border-label="$border_label" \
    --no-multi \
    --no-clear)
  status=$?
  case "$status" in
    0) return 0 ;;
    1 | 130)
      SELECTED=""
      return 1
      ;;
    *)
      printf 'Error: fzf failed with exit %s\n' "$status" >&2
      exit "$status"
      ;;
  esac
}

is_listed() {
  local selected=$1
  local rows=$2
  local row
  while IFS= read -r row; do
    if [ "$row" = "$selected" ]; then
      return 0
    fi
  done <<<"$rows"
  return 1
}

load_sessions() {
  local json
  local status
  json=$("${REX_BASE[@]}" ls --json)
  status=$?
  if [ "$status" -ne 0 ]; then
    exit "$status"
  fi
  SESSIONS_JSON=$json
}

session_rows() {
  printf '%s' "$SESSIONS_JSON" | "$JQ_BIN" -r "$SESSION_ROWS_FILTER"
}

manager_projects() {
  local json
  local status
  local rows
  local selected
  local args

  json=$("${REX_BASE[@]}" do list_projects --json)
  status=$?
  if [ "$status" -ne 0 ]; then
    exit "$status"
  fi
  rows=$(printf '%s' "$json" | "$JQ_BIN" -r '(.projects // []) | .[] | select(. != "")')
  status=$?
  if [ "$status" -ne 0 ]; then
    fail "could not read projects from list_projects"
  fi
  if [ -z "$rows" ]; then
    exit 0
  fi

  if ! choose "$rows" "> " "rex-session-manager" "1.."; then
    exit 0
  fi
  selected=$SELECTED
  if [ -z "$selected" ]; then
    fail "fzf returned an empty selection"
  fi
  if ! is_listed "$selected" "$rows"; then
    fail "the selection is not one of the listed projects"
  fi

  args=$("$JQ_BIN" -cn --arg project "$selected" '{project:$project}')
  status=$?
  if [ "$status" -ne 0 ]; then
    fail "could not encode the project arguments"
  fi

  "${REX_C[@]}" do jump_project --args "$args" --json >/dev/null
  status=$?
  if [ "$status" -ne 0 ]; then
    exit "$status"
  fi
  exit 0
}

manager_active() {
  local status
  local rows
  local selected
  local id

  load_sessions
  rows=$(session_rows)
  status=$?
  if [ "$status" -ne 0 ]; then
    fail "could not read sessions from rex ls --json"
  fi
  if [ -z "$rows" ]; then
    exit 0
  fi

  if ! choose "$rows" "> " "rex-session-manager (active-sessions)" "2.."; then
    exit 0
  fi
  selected=$SELECTED
  if [ -z "$selected" ]; then
    fail "fzf returned an empty selection"
  fi
  if ! is_listed "$selected" "$rows"; then
    fail "the selection is not one of the listed sessions"
  fi
  id=${selected%%$'\t'*}
  if [ -z "$id" ]; then
    fail "the selected row has no session ID"
  fi

  "${REX_C[@]}" do session.select "session_id=$id" >/dev/null
  status=$?
  if [ "$status" -ne 0 ]; then
    exit "$status"
  fi
  exit 0
}

manager_close() {
  local status
  local rows
  local selected
  local id
  local display
  local answer

  load_sessions
  rows=$(session_rows)
  status=$?
  if [ "$status" -ne 0 ]; then
    fail "could not read sessions from rex ls --json"
  fi
  if [ -z "$rows" ]; then
    exit 0
  fi

  if ! choose "$rows" "> " "rex-session-manager (kill-session)" "2.."; then
    exit 0
  fi
  selected=$SELECTED
  if [ -z "$selected" ]; then
    fail "fzf returned an empty selection"
  fi
  if ! is_listed "$selected" "$rows"; then
    fail "the selection is not one of the listed sessions"
  fi
  id=${selected%%$'\t'*}
  if [ -z "$id" ]; then
    fail "the selected row has no session ID"
  fi
  display=${selected#*$'\t'}

  printf 'Close session %s (%s)? [y/N] ' "$display" "$id"
  answer=""
  if ! IFS= read -r answer; then
    answer=""
  fi
  if [ "$answer" != "y" ]; then
    printf 'Keeping session %s.\n' "$display"
    exit 0
  fi

  "${REX_BASE[@]}" kill "$id" >/dev/null
  status=$?
  if [ "$status" -ne 0 ]; then
    exit "$status"
  fi
  exit 0
}

case "$mode" in
  projects) manager_projects ;;
  active) manager_active ;;
  close) manager_close ;;
esac
