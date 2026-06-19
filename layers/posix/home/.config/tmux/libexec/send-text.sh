#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

PANE="$1"
BUF="send-text-$$-$RANDOM"
TM=(tmux -S "${TMUX_ROOT:-${TMUX%%,*}}")

"${TM[@]}" load-buffer -b "$BUF" -- -

CODE=0
"${TM[@]}" paste-buffer -r -p -d -b "$BUF" -t "$PANE" || CODE="$?"

if ! ((CODE)); then
  "${TM[@]}" send-keys -t "$PANE" -- Enter
fi

exit "$CODE"
