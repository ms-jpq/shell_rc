#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

REPL_ANCESTOR_PATHS="${REPL_ANCESTOR_PATHS:-}"
REPL_FILE_NAME="${REPL_FILE_NAME:-}"
REPL_LINE_COL="${REPL_LINE_COL:-}"
REPL_LINE_COUNT="${REPL_LINE_COUNT:-}"
REPL_LINE_ROW="${REPL_LINE_ROW:-}"
REPL_PARENT_PATH="${REPL_PARENT_PATH:-}"
REPL_PRETTY_NAME="${REPL_PRETTY_NAME:-}"
REPL_TARGET="${REPL_TARGET:-}"

TMUX_SOCKET="${TMUX:-}"
SOCKET="${__TMUX_ROOT_SOCKET__:-${TMUX_SOCKET%%,*}}"
CURRENT_PANE="${__TMUX_ROOT_PANE__:-${TMUX_PANE:-}}"

if [[ -z $SOCKET || -z $CURRENT_PANE ]]; then
  printf -- ' ∅' >&2
  exit 1
fi

case "$REPL_TARGET" in
'')
  readarray -d ':' -t ANCESTOR_PATHS < <(printf '%s:' "$REPL_ANCESTOR_PATHS")
  declare -A -- ANCESTORS=()
  for ANCESTOR_PATH in "${ANCESTOR_PATHS[@]}"; do
    ANCESTORS["$ANCESTOR_PATH"]=1
  done

  TM=(tmux -S "$SOCKET")
  CURRENT_WINDOW="$("${TM[@]}" display-message -t "$CURRENT_PANE" -p -F '#{window_id}')"

  FORMAT=$'#{pane_id}\t#{window_id}\t#{window_active}\t#{session_name} -> #{window_index} -> #{pane_index}\t#{?#{pane_path},#{pane_path},#{pane_current_path}}'

  read -r -d '' AWK << 'AWK' || true
BEGIN {
  ACTIVE = 0
  GLYPH = ""
  LABEL = ""
  SAME_WINDOW = 0
}

$1 != PANE {
  ACTIVE = $3 == "1" ? 0 : 1
  SAME_WINDOW = $2 == WINDOW ? 0 : 1
  GLYPH = SAME_WINDOW == 0 ? SAME_WINDOW_GLYPH : ACTIVE == 0 ? ACTIVE_GLYPH : ""
  LABEL = $4 " " $5
  if (GLYPH != "") {
    LABEL = LABEL " " GLYPH
  }
  printf "%d\t%d\t%09d\t%s\t%s\n", ACTIVE, SAME_WINDOW, NR, $1, LABEL
}
AWK
  PARSE=(
    awk -F '\t'
    -v ACTIVE_GLYPH='⛶'
    -v SAME_WINDOW_GLYPH='▣'
    -v PANE="$CURRENT_PANE"
    -v WINDOW="$CURRENT_WINDOW"
    "$AWK"
  )

  "${TM[@]}" list-panes -a -F "$FORMAT" | while IFS=$'\t' read -r PANE_ID WINDOW_ID PANE_ACTIVE LOCATION PANE_PATH; do
    if [[ $PANE_PATH == "$REPL_PARENT_PATH" || $PANE_PATH == "$REPL_PARENT_PATH/"* || -v "ANCESTORS[$PANE_PATH]" ]]; then
      printf -- '%s\t%s\t%s\t%s\t%s\n' "$PANE_ID" "$WINDOW_ID" "$PANE_ACTIVE" "$LOCATION" "$PANE_PATH"
    fi
  done | "${PARSE[@]}" | LC_ALL=C.UTF-8 sort -t $'\t' -k1,1n -k2,2n -k3,3n | awk -F '\t' '{ printf "%s\t%s%c", $4, $5, 0 }'
  ;;
*)
  PANE="${REPL_TARGET%%$'\t'*}"

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
  MARKER = NR == ROW ? "→" : " "
  printf "%s %*d | %s\n", MARKER, WIDTH, NR, $0
}
AWK

  PRINT_CONTEXT=(
    awk
    -v COL="$REPL_LINE_COL"
    -v COUNT="$REPL_LINE_COUNT"
    -v DISPLAY="$REPL_PRETTY_NAME"
    -v ROW="$REPL_LINE_ROW"
    -v WINDOW=6
    --
    "$AWK"
  )

  "${PRINT_CONTEXT[@]}" < "$REPL_FILE_NAME" | ~/.config/tmux/libexec/send-text.sh "$PANE"

  printf '%s' "⮕  [$PANE]"
  ;;
esac
