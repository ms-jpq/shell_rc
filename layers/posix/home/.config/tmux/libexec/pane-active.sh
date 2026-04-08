#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

TMUX_PANE="${1:-"$TMUX_PANE"}"

ACTIVE="$(tmux display-message -t "$TMUX_PANE" -p '#{pane_active}#{window_active}#{session_active}')"
[[ $ACTIVE == '111' ]]
