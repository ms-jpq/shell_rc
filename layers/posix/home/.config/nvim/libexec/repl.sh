#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

FILE="$1"
COUNT="$2"
ROW="$3"
COL="$4"
PANE="$5"
DISPLAY="$6"

WINDOW=6

read -r -d '' AWK << 'AWK' || true
BEGIN {
  WIDTH = length(COUNT)
  LO = ROW - WINDOW
  HI = ROW + WINDOW
  LO = LO < 1 ? 1 : LO
  HI = HI > COUNT ? COUNT : HI
  printf "REPL> %s:%d:%d\n", DISPLAY, ROW, COL
}

NR < LO {
  next
}

NR > HI {
  exit
}

{
  MARKER = NR == ROW ? "->" : "  "
  printf "%s %*d | %s\n", MARKER, WIDTH, NR, $0
}
AWK

awk -v DISPLAY="$DISPLAY" -v ROW="$ROW" -v COL="$COL" -v COUNT="$COUNT" -v WINDOW="$WINDOW" "$AWK" < "$FILE" | ~/.config/tmux/libexec/send-text.sh "$PANE"

printf '%s' "⮕  [$PANE]"
