#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

FILE="$1"
ROW="$2"
COL="$3"
COUNT="$4"
PANE="$5"
WINDOW=6

awk -v FILE="$FILE" -v ROW="$ROW" -v COL="$COL" -v COUNT="$COUNT" -v WINDOW="$WINDOW" -f /dev/stdin "$FILE" << 'AWK' | ~/.config/tmux/libexec/send-text.sh "$PANE"
BEGIN {
  WIDTH = length(COUNT)
  LO = ROW - WINDOW
  HI = ROW + WINDOW
  LO = LO < 1 ? 1 : LO
  HI = HI > COUNT ? COUNT : HI
  printf "REPL> %s:%d:%d\n", FILE, ROW, COL
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

printf '%s' "⮕  [$PANE]"
