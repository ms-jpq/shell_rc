#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

ARGV=(
  git log
  --relative
  --all
  --name-only
  --color --pretty='format:%ad'
  -z
)

declare -A -- COUNTS=() TIMES=()

TMP="$(mktemp)"
"${ARGV[@]}" >"$TMP"

HEAD=1
while read -d '' -r LINE; do
  if [[ -z "$LINE" ]]; then
    HEAD=1
    continue
  fi

  if ((HEAD)); then
    TIME="${LINE%%$'\n'*}"
    LINE="${LINE#*$'\n'}"
    HEAD=0
  else
    TIMES["$LINE"]="$TIME"
    COUNT="${COUNTS["$LINE"]:-0}"
    COUNTS["$LINE"]="$((COUNT + 1))"
  fi
done <"$TMP"

for LINE in "${!COUNTS[@]}"; do
  COUNT="${COUNTS["$LINE"]}"
  TIME="${TIMES["$LINE"]}"
  TIME="${TIME//[[:space:]]/'+'}"
  printf -- '%s %s %s\n' "$COUNT" "$TIME" "$LINE"
done | column -t
