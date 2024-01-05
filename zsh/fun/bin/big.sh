#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

OPTS='f:'
LONG_OPTS='font:'
GO="$(getopt --options="$OPTS" --longoptions="$LONG_OPTS" --name="$0" -- "$@")"
eval -- set -- "$GO"

while (($#)); do
  case "$1" in
  -f | --font)
    FONT="$2"
    shift -- 2
    ;;
  --)
    shift -- 1
    break
    ;;
  *)
    exit 1
    ;;
  esac
done

if ! [[ -v FONT ]]; then
  FONTS=("$(figlet -I 2)"/**.flf)
  FONT="${FONTS[$((RANDOM % ${#FONTS[@]}))]}"
fi

if [[ -v SHOW_FONT ]]; then
  printf -- '%s' "$FONT"
  exit
fi

COLS=$(tput -- cols)

ARGS=(
  -c
  -w "$COLS"
  -f "$FONT"
)

if [[ -t 0 ]]; then
  TEXT="$*"
else
  TEXT="$(</dev/stdin)"
fi

TEXT="${TEXT:-BIGLY}"
LINES="$(figlet "${ARGS[@]}" <<<"$TEXT")"
DEL="$(tr -d '[:space:]' <<<"$LINES")"

if [[ -z "$DEL" ]]; then
  exec -- "$0" "$@"
else
  printf -- '%s\n' "$LINES"
fi
