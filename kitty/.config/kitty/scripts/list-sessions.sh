#!/usr/bin/env bash

set -euo pipefail

script_dir="$(dirname "$0")"
source "$script_dir/session-common.sh"

menu_lines="$(build_menu_lines all || true)"
if [[ -z "$menu_lines" ]]; then
  echo "No session files found."
  exit 1
fi

selection="$(pick_session "> " "kitty-session-manager" "$menu_lines" || true)"
if [[ -z "$selection" ]]; then
  exit 0
fi

selected_session_file="$(printf "%s" "$selection" | awk -F'\t' '{print $3}')"
if [[ -n "$selected_session_file" && -f "$selected_session_file" ]]; then
  run_kitty_rc action goto_session "$selected_session_file" >/dev/null 2>&1 || true
fi
