#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

PANE="${1:-${__TMUX_ROOT_PANE__:-$TMUX_PANE}}"
TM=(tmux -S "${2:-${__TMUX_ROOT_SOCKET__:-${TMUX%%,*}}}")

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
