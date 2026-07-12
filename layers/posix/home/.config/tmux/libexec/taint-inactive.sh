#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

PANE="${1:-${TMUX_ROOT_PANE:-$TMUX_PANE}}"
TM=(tmux -S "${2:-${TMUX_ROOT:-${TMUX%%,*}}}")

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

"${TM[@]}" set-option -t "$PANE" -p window-style 'bg=#{tmux_colour_bell}'
