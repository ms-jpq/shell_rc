#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

COLS=$(tput -- cols)
WRAP=$((COLS / 3))

RAW="$(cowsay -l | tail -n +2)"
NORM="${RAW//$'\n'/' '}"
readarray -t -d ' ' -- COWS < <(printf -- '%s' "$NORM")
COW="${COWS[$((RANDOM % ${#COWS[@]}))]}"

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
  TEXT="$(</dev/stdin)"
fi

TEXT="${TEXT:-moo}"
exec -- cowsay "${ARGS[@]}" <<<"$TEXT"