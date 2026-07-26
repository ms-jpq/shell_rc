#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

FILE="$1"
ROW="$2"
COL="$3"
COUNT="$4"
PANE="$5"

awk -v file="$FILE" -v row="$ROW" -v col="$COL" -v count="$COUNT" -f /dev/stdin "$FILE" << 'AWK' | ~/.config/tmux/libexec/send-text.sh "$PANE"
BEGIN {
  width = length(count)
  printf ">>> %s:%d:%d\n", file, row, col
}

{
  marker = NR == row ? "->" : "  "
  printf "%s %*d | %s\n", marker, width, NR, $0
}
AWK

printf '%s' "⮕  [$PANE]"
