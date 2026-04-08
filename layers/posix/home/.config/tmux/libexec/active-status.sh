#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

exec -- tmux display-message -t "${*:-"$TMUX_PANE"}" -p '#{session_active}#{window_active}#{pane_active}'
