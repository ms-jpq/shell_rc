#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

git diff --name-only -z "$@"

readarray -t -d '' -- DIFFS <<< ""

SPLIT=(new-window -a)
for NEW in "${DIFFS[@]}"; do
  OLD=''
  NEW=''
  tmux "${SPLIT[@]}" -c "$PWD" -- nvim -d -- "$OLD" "$NEW"
  SPLIT=(split-window)
done
