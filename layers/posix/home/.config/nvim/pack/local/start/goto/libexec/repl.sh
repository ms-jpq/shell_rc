#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

: "${REPL_FILE_NAME:?}"
: "${REPL_LINE_COL:?}"
: "${REPL_LINE_COUNT:?}"
: "${REPL_LINE_ROW:?}"
: "${REPL_PRETTY_NAME:?}"
: "${REPL_TARGET:?}"

SOCKET="${__TMUX_ROOT_SOCKET__:-${TMUX%%,*}}"
CURRENT_PANE="${__TMUX_ROOT_PANE__:-${TMUX_PANE:-}}"

if [[ -z $SOCKET || -z $CURRENT_PANE ]]; then
  exit 0
fi

case "$REPL_TARGET" in
"")
  TM=(tmux -S "$SOCKET")
  CURRENT_WINDOW="$("${TM[@]}" display-message -t "$CURRENT_PANE" -p -F '#{window_id}')"

  FORMAT=$'#{pane_id}\t#{window_id}\t#{window_active}\t#{session_name} -> #{window_index} -> #{pane_index}\t#{?#{pane_path},#{pane_path},#{pane_current_path}}'

  read -r -d '' AWK << 'AWK' || true
$1 != pane {
  active = $3 == "1" ? 0 : 1
  same_window = $2 == window ? 0 : 1
  glyph = same_window == 0 ? "\342\226\243" : active == 0 ? "\342\233\266" : ""
  label = $4 " " $5
  if (glyph != "") {
    label = label " " glyph
  }
  printf "%d\t%d\t%09d\t%s\t%s\n", active, same_window, NR, $1, label
}
AWK

  "${TM[@]}" list-panes -a -F "$FORMAT" | awk -F '\t' -v pane="$CURRENT_PANE" -v window="$CURRENT_WINDOW" "$AWK" | LC_ALL=C.UTF-8 sort -t $'\t' -k1,1n -k2,2n -k3,3n | awk -F '\t' '{ printf "%s\t%s%c", $4, $5, 0 }'
  ;;
*)

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

  GEN=(
    awk
    -v COL="$REPL_LINE_COL"
    -v COUNT="$REPL_LINE_COUNT"
    -v DISPLAY="$REPL_PRETTY_NAME"
    -v ROW="$REPL_LINE_ROW"
    -v WINDOW=6
    --
    "$AWK"
  )

  "${GEN[@]}" < "$REPL_FILE_NAME" | ~/.config/tmux/libexec/send-text.sh "$PANE"

  printf '%s' "⮕  [$PANE]"
  ;;
esac
