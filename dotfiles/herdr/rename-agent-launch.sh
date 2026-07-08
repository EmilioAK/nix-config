#!/bin/sh
set -eu

herdr_bin="${HERDR_BIN_PATH:-herdr}"
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
helper="${HERDR_RENAME_AGENT_PROMPT_HELPER:-$config_home/herdr/rename-agent-prompt.sh}"

if [ -n "${HERDR_RENAME_AGENT_TARGET:-}" ]; then
  target="$HERDR_RENAME_AGENT_TARGET"
else
  pane_json="$(env -u HERDR_PANE_ID -u HERDR_TAB_ID -u HERDR_WORKSPACE_ID "$herdr_bin" pane current)"
  target="$(printf "%s\n" "$pane_json" | sed -n "s/.*\"pane_id\":\"\([^\"]*\)\".*/\1/p")"
fi

if [ -z "$target" ]; then
  exit 1
fi

split_json="$("$herdr_bin" pane split "$target" --direction down --ratio "${HERDR_RENAME_AGENT_RATIO:-0.25}" --focus)"
prompt_pane="$(printf "%s\n" "$split_json" | sed -n "s/.*\"pane_id\":\"\([^\"]*\)\".*/\1/p")"

if [ -z "$prompt_pane" ]; then
  exit 1
fi

sq() {
  printf "'%s'" "$(printf "%s" "$1" | sed "s/'/'\\\\''/g")"
}

cmd="env HERDR_BIN_PATH=$(sq "$herdr_bin") HERDR_RENAME_AGENT_TARGET=$(sq "$target") HERDR_RENAME_AGENT_PROMPT_PANE=$(sq "$prompt_pane") sh $(sq "$helper")"
"$herdr_bin" pane run "$prompt_pane" "$cmd"
