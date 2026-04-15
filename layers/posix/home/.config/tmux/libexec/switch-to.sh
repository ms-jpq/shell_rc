#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

LISTED="$1"
SESSION="$2"
shift -- 2

ARGV=()
if (($#)); then
  ARGV+=(bash -Eeu -- "$*")
fi

if [[ -v TMUX ]]; then
  if ((LISTED)); then
    exec -- tmux switch -t "$SESSION"
  fi

  tmux new-session -d -c "$HOME" -s "$SESSION"
  exec -- tmux switch-client -t "$SESSION"
else
  exec -- tmux new-session -A -c "$HOME" -s "$SESSION" -- "${ARGV[@]}"
fi
