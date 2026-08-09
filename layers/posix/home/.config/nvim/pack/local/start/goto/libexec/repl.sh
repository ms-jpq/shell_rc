#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

: "${REPL_ANCESTOR_PATHS?}"
: "${REPL_FILE_NAME?}"
: "${REPL_IFS?}"
: "${REPL_LINE_COL?}"
: "${REPL_LINE_COUNT?}"
: "${REPL_LINE_ROW?}"
: "${REPL_PARENT_PATH?}"
: "${REPL_PRETTY_NAME?}"
: "${REPL_TARGET?}"

TMUX_SOCKET="${TMUX:-}"
SOCKET="${__TMUX_ROOT_SOCKET__:-${TMUX_SOCKET%%,*}}"
CURRENT_PANE="${__TMUX_ROOT_PANE__:-${TMUX_PANE:-}}"

if [[ -z $SOCKET || -z $CURRENT_PANE ]]; then
  exit 1
fi

case "$REPL_TARGET" in
'')

  REL_TARGET_PATH=""
  if [[ $REPL_FILE_NAME == *.md ]]; then
    read -r -d '' AWK << 'AWK' || true
BEGIN {
  FRONTMATTER = 0
}

NR == 1 {
  if ($0 == "---") {
    FRONTMATTER = 1
    next
  }
  exit
}

FRONTMATTER && ($0 == "---" || $0 == "...") {
  exit
}

FRONTMATTER && /^rel-target:[[:space:]]*/ {
  sub(/^rel-target:[[:space:]]*/, "", $0)
  sub(/[[:space:]]+$/, "", $0)
  print
  exit
}
AWK
    REL_TARGET_PATH="$(awk -- "$AWK" < "$REPL_FILE_NAME")"
  fi

  TM=(tmux -S "$SOCKET")
  CURRENT_WINDOW="$("${TM[@]}" display-message -t "$CURRENT_PANE" -p -F '#{window_id}')"

  readarray -d ':' -t ANCESTOR_PATHS < <(printf -- '%s' "$REPL_ANCESTOR_PATHS")
  declare -A -- ANCESTORS=()
  for ANCESTOR_PATH in "${ANCESTOR_PATHS[@]}"; do
    ANCESTORS["$ANCESTOR_PATH"]=1
  done

  FORMAT_FIELDS=(
    '#{?pane_active,0,1}'
    "#{?#{==:#{window_id},$CURRENT_WINDOW},0,1}"
    '#{pane_id}'
    '#{window_id}'
    '#{pane_active}'
    '#{session_name} → #{window_index}:#{pane_index}'
    '#{?#{pane_path},#{pane_path},#{pane_current_path}}'
  )
  printf -v FORMAT -- "%s$REPL_IFS" "${FORMAT_FIELDS[@]}"
  FORMAT="${FORMAT%"$REPL_IFS"}"

  "${TM[@]}" list-panes -a -F "$FORMAT" | LC_ALL=C.UTF-8 sort --stable --field-separator "$REPL_IFS" --key 1,1n --key 2,2n | cut --delimiter "$REPL_IFS" --fields 3- | while IFS="$REPL_IFS" read -r PANE_ID WINDOW_ID PANE_ACTIVE SLUG PANE_PATH; do
    if [[ $PANE_ID == "$CURRENT_PANE" ]]; then
      continue
    fi
    if [[ -n $REL_TARGET_PATH ]]; then
      if [[ $PANE_PATH != "$REL_TARGET_PATH" ]]; then
        continue
      fi
    elif [[ $PANE_PATH != "$REPL_PARENT_PATH" ]] && [[ $PANE_PATH != "$REPL_PARENT_PATH/"* ]] && [[ -z ${ANCESTORS["$PANE_PATH"]+_} ]]; then
      continue
    fi

    DECOR=''
    if [[ $WINDOW_ID == "$CURRENT_WINDOW" ]]; then
      DECOR+=" ▣"
    elif [[ $PANE_ACTIVE == 1 ]]; then
      DECOR+=" ⛶"
    fi
    printf -- '%s\0' "$PANE_ID$REPL_IFS$SLUG ${PANE_PATH/#"$HOME"/"~"}$DECOR"
  done
  ;;
*)
  PANE_ID="${REPL_TARGET%%"$REPL_IFS"*}"

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

  "${PRINT_CONTEXT[@]}" < "$REPL_FILE_NAME" | ~/.config/tmux/libexec/send-text.sh "$PANE_ID"

  printf '%s' "⮕  [$PANE_ID]"
  ;;
esac
