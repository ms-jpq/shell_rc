#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

TMUX_PANE="${1:-"$TMUX_PANE"}"
exec -- tmux set-option -t "$TMUX_PANE" -p window-style 'bg=#f5eeff'
