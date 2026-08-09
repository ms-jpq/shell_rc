#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

SESSION="$1"
shift -- 1

if [[ -t 0 ]] && [[ -z ${TMUX:-} ]]; then
  exec -- tmux new-session -A -c "$HOME" -s "$SESSION" -- "$@"
fi

if ! tmux has-session -t "=$SESSION" 2> /dev/null; then
  tmux new-session -d -c "$HOME" -s "$SESSION" -- "$@"
fi

if [[ -t 0 ]]; then
  exec -- tmux switch-client -t "=$SESSION"
fi
