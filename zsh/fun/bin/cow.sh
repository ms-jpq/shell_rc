#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

OPTS='f:'
LONG_OPTS='font:'
GO="$(getopt --options="$OPTS" --longoptions="$LONG_OPTS" --name="$0" -- "$@")"
eval -- set -- "$GO"

while (($#)); do
  case "$1" in
  -f | --font)
    COW="$2"
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

COLS=$(tput -- cols)
WRAP=$((COLS / 3))

if ! [[ -v COW ]]; then
  RAW="$(cowsay -l | tail -n +2)"
  NORM="${RAW//$'\n'/' '}"
  readarray -t -d ' ' -- COWS < <(printf -- '%s' "$NORM")
  COW="${COWS[$((RANDOM % ${#COWS[@]}))]}"
fi

STYLES=(-b -d -g -p -s -t -w -y)
STYLE="${STYLES[$((RANDOM % ${#STYLES[@]}))]}"

ARGS=(
  -W
  "$WRAP"
  -f
  "$COW"
  "$STYLE"
)

if [[ -t 0 ]]; then
  TEXT="$*"
else
  TEXT="$(< /dev/stdin)"
fi

TEXT="${TEXT:-"$(fortune)"}"
exec -- cowsay "${ARGS[@]}" <<< "$TEXT"
