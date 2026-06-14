#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

SESSION="$1"
shift -- 1

ARGV=()
if (($#)); then
  ARGV+=(bash -Eeu -- "$*")
fi

if [[ -v TMUX ]]; then
  if ! tmux has-session -t "=$SESSION" 2> /dev/null; then
    tmux new-session -d -c "$HOME" -s "$SESSION" -- "${ARGV[@]}"
  fi

  exec -- tmux switch-client -t "$SESSION"
else
  exec -- tmux new-session -A -c "$HOME" -s "$SESSION" -- "${ARGV[@]}"
fi
