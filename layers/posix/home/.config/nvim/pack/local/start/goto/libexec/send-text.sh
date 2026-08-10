#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

PANE="$1"
BUF="send-text-$$-$RANDOM"
TM=(tmux -S "${__TMUX_ROOT_SOCKET__:-${TMUX%%,*}}")

"${TM[@]}" load-buffer -b "$BUF" -- -

CODE=0
"${TM[@]}" paste-buffer -r -p -d -b "$BUF" -t "$PANE" || CODE="$?"

if ! ((CODE)); then
  "${TM[@]}" send-keys -t "$PANE" -- Enter
fi

exit "$CODE"
