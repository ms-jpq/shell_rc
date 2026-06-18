#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

TM=(tmux -S "${TMUX_ROOT:-${TMUX%%,*}}")
PANE="${1:-$TMUX_PANE}"

STATUS="$("${TM[@]}" display-message -t "$PANE" -p '#{session_active}#{window_active}#{pane_active}')"

case "$STATUS" in
111)
  exit
  ;;
110) ;;
*)
  "${TM[@]}" set-option -t "$PANE" -w window-status-style 'reverse'
  ;;
esac

"${TM[@]}" set-option -t "$PANE" -p window-style 'bg=#f5eeff'
