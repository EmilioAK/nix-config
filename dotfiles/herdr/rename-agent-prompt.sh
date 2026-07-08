#!/bin/sh
set -eu

herdr_bin="${HERDR_BIN_PATH:-herdr}"
target="${HERDR_RENAME_AGENT_TARGET:?missing HERDR_RENAME_AGENT_TARGET}"
prompt_pane="${HERDR_RENAME_AGENT_PROMPT_PANE:-}"

cleanup() {
  if [ -n "$prompt_pane" ]; then
    "$herdr_bin" pane close "$prompt_pane" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT INT TERM

printf "New agent label for %s (blank clears): " "$target"
IFS= read -r name || exit 0

if [ -n "$name" ]; then
  "$herdr_bin" agent rename "$target" "$name"
  printf "Renamed agent on %s to %s.\n" "$target" "$name"
else
  "$herdr_bin" agent rename "$target" --clear
  printf "Cleared agent label on %s.\n" "$target"
fi

sleep 0.6
