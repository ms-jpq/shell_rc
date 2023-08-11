#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

ARGV=(
  git log
  --relative
  --all
  --name-only
  --color --pretty='format:/%Cblue%ad%Creset'
  -z
)

declare -A -- COUNTS=() TIMES=()

TMP="$(mktemp)"
"${ARGV[@]}" >"$TMP"

while read -d '' -r LINE; do
  while :; do
    case "$LINE" in
    /*)
      TIME="${LINE%%$'\n'*}"
      LINE="${LINE#*$'\n'}"
      if [[ "$TIME" == "$LINE" ]]; then
        LINE=''
        break
      fi
      ;;
    *)
      break
      ;;
    esac
  done

  if [[ -z "$LINE" ]]; then
    continue
  fi

  TIME="${TIME#*/}"
  TIMES["$LINE"]="$TIME"
  COUNT="${COUNTS["$LINE"]:-0}"
  COUNTS["$LINE"]="$((COUNT + 1))"
done <"$TMP"

for LINE in "${!COUNTS[@]}"; do
  COUNT="${COUNTS["$LINE"]}"
  TIME="${TIMES["$LINE"]}"
  printf -- '%s %s %s\n' "$COUNT" "$TIME" "$LINE"
done | sort --key 1 --numeric-sort --reverse | column -t
