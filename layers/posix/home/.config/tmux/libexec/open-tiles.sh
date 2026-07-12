#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

readarray -t -d '' -- LINES

for I in "${!LINES[@]}"; do
  LINE="${LINES[$I]}"

  if ((I % 4 == 0)); then
    SPLIT=(new-window -a)
  else
    SPLIT=(split-window)
  fi

  tmux "${SPLIT[@]}" -c "$LINE" -- "$@"
  if ((I % 4 == 3)) || ((I == ${#LINES[@]} - 1)); then
    tmux select-layout -- tiled
  fi
done
