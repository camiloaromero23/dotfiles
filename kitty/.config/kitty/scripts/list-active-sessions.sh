#!/usr/bin/env bash

set -euo pipefail

script_dir="$(dirname "$0")"
source "$script_dir/session-common.sh"

menu_lines="$(build_menu_lines active || true)"
if [[ -z "$menu_lines" ]]; then
  echo "No active sessions found."
  exit 1
fi

selection="$(pick_session "> " "kitty-session-manager (active-sessions)" "$menu_lines" || true)"
if [[ -z "$selection" ]]; then
  exit 0
fi

selected_session_file="$(printf "%s" "$selection" | awk -F'\t' '{print $3}')"
if [[ -n "$selected_session_file" && -f "$selected_session_file" ]]; then
  run_kitty_rc action goto_session "$selected_session_file" >/dev/null 2>&1 || true
fi
