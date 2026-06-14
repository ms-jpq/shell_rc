#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

TMUX_PANE="${1:-$TMUX_PANE}"

STATUS="$(tmux display-message -t "$TMUX_PANE" -p '#{session_active}#{window_active}#{pane_active}')"

case "$STATUS" in
111)
  exit
  ;;
110) ;;
*)
  tmux set-option -t "$TMUX_PANE" -w window-status-style 'reverse'
  ;;
esac

tmux set-option -t "$TMUX_PANE" -p window-style 'bg=#f5eeff'
