#!/usr/bin/env bash

set -euo pipefail

kitty_bin="/opt/homebrew/bin/kitty"
fzf_bin="${FZF_BIN:-/run/current-system/sw/bin/fzf}"
jq_bin="${JQ_BIN:-/run/current-system/sw/bin/jq}"
sessions_dir="$HOME/.config/kitty/sessions"
log_file="${TMPDIR:-/tmp}/kitty-active-sessions.log"

log_debug() {
  printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >>"$log_file"
}

if [[ ! -x "$fzf_bin" ]]; then
  echo "fzf binary not found at: $fzf_bin"
  exit 1
fi

if [[ ! -x "$jq_bin" ]]; then
  echo "jq binary not found at: $jq_bin"
  exit 1
fi

if [[ ! -x "$kitty_bin" ]]; then
  echo "kitty binary not found at: $kitty_bin"
  exit 1
fi

sock=""
shopt -s nullglob
kitty_sockets=(/tmp/kitty-*)
shopt -u nullglob
for candidate_socket in "${kitty_sockets[@]}"; do
  if [[ -S "$candidate_socket" ]]; then
    sock="$candidate_socket"
    break
  fi
done

run_kitty_rc() {
  local output=""

  log_debug "run_kitty_rc: kitty @ $*"
  output="$($kitty_bin @ "$@" 2>/dev/null || true)"
  if [[ -n "$output" ]]; then
    log_debug "run_kitty_rc: direct output received"
    printf "%s" "$output"
    return 0
  fi

  if [[ -n "$sock" ]]; then
    log_debug "run_kitty_rc: fallback socket unix:${sock}"
    "$kitty_bin" @ --to "unix:${sock}" "$@" 2>/dev/null || true
  fi
}

escape_ere() {
  printf '%s' "$1" | sed -E 's/[][(){}.^$*+?|\\-]/\\&/g'
}

session_is_active() {
  local session_name="$1"
  local match_expr
  local match_output

  match_expr="^$(escape_ere "$session_name")$"
  log_debug "session_is_active: ${session_name}"
  match_output="$(run_kitty_rc ls --match "session:${match_expr}")"

  if [[ -z "$match_output" ]]; then
    log_debug "session_is_active: no output for ${session_name}"
    return 1
  fi

  log_debug "session_is_active: output received for ${session_name}"

  printf "%s" "$match_output" | "$jq_bin" -e 'map(.tabs | length) | add > 0' >/dev/null 2>&1
}

build_active_session_cwds() {
  local kitty_ls_output=""

  kitty_ls_output="$(run_kitty_rc ls)"
  if [[ -z "$kitty_ls_output" ]]; then
    return 1
  fi

  printf "%s" "$kitty_ls_output" | "$jq_bin" -r '
    [
      .[]
      | .tabs[]?
      | .windows[]?
      | (.env.PWD // .cwd)
      | select(. != null and . != "")
    ]
    | unique
    | .[]
  ' 2>/dev/null
}

session_matches_active_cwds() {
  local session_file="$1"
  local active_cwds="$2"
  local session_cwds=""
  local session_cwd

  session_cwds="$(awk '/^cd / { print substr($0, 4) }' "$session_file" | sort -u)"
  if [[ -z "$session_cwds" ]]; then
    return 1
  fi

  while IFS= read -r session_cwd; do
    [[ -n "$session_cwd" ]] || continue
    if [[ "$session_cwd" == ~* ]]; then
      session_cwd="$HOME${session_cwd:1}"
    fi
    if printf "%s\n" "$active_cwds" | grep -Fx -- "$session_cwd" >/dev/null 2>&1; then
      return 0
    fi
  done <<< "$session_cwds"

  return 1
}

build_menu_lines() {
  local mode="$1"
  local session_file
  local session_files=()
  local session_name
  local active_session_cwds=""
  local rows=""

  if [[ ! -d "$sessions_dir" ]]; then
    return 1
  fi

  log_debug "build_menu_lines: mode=${mode} KITTY_WINDOW_ID=${KITTY_WINDOW_ID:-} KITTY_LISTEN_ON=${KITTY_LISTEN_ON:-} sock=${sock:-}"

  shopt -s nullglob
  session_files=("$sessions_dir"/*.session)
  shopt -u nullglob

  if [[ "$mode" == "active" ]]; then
    active_session_cwds="$(build_active_session_cwds || true)"
    if [[ -n "$active_session_cwds" ]]; then
      log_debug "build_menu_lines: using cwd fast path=$(printf '%s' "$active_session_cwds" | tr '\n' ' ')"
    else
      log_debug "build_menu_lines: cwd fast path unavailable, falling back"
    fi
  fi

  for session_file in "${session_files[@]}"; do
    session_name="$(basename "$session_file" .session)"

    if [[ "$mode" == "active" ]]; then
      if [[ -n "$active_session_cwds" ]]; then
        if ! session_matches_active_cwds "$session_file" "$active_session_cwds"; then
          continue
        fi
      elif ! session_is_active "$session_name"; then
        continue
      fi
    fi

    rows+="$session_name"
    rows+=$'\t'
    rows+="$session_file"
    rows+=$'\n'
  done

  if [[ -z "$rows" ]]; then
    return 1
  fi

  printf "%s" "$rows" | sort -t$'\t' -k1,1 | awk -F'\t' '{
    idx = NR
    session_name = $1
    session_file = $2
    printf "%d\t%s\t%s\t%s\n", idx, session_name, session_file, session_name
  }'
}

pick_session() {
  local prompt="$1"
  local border_label="$2"
  local menu_lines="$3"
  local selection=""

  selection="$({
    printf "%s\n" "$menu_lines" |
      "$fzf_bin" \
        --prompt "$prompt" \
        --border=rounded \
        --border-label "$border_label" \
        --delimiter $'\t' \
        --with-nth=4.. \
        --no-multi \
        --no-clear
  } || true)"

  if [[ -z "$selection" ]]; then
    return 1
  fi

  printf "%s" "$selection"
}
