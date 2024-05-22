#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

case "${SCRIPT_MODE:-""}" in
preview)
  readarray -t -d '' -- LINES
  for LINE in "${LINES[@]}"; do
    FILE="${LINE#*$'\n'}"
    printf -- '%s\n\n' "$FILE"
    git log --relative --all --follow --stat --color -- "$FILE"
    printf -- '\n'
  done
  ;;
execute)
  readarray -t -d '' -- LINES
  for LINE in "${LINES[@]}"; do
    FILE="${LINE#*$'\n'}"
    printf -- '%q\n' "$FILE"
  done
  ;;
*)
  ARGV=(
    git log
    --relative
    --all
    --name-only
    --color --pretty='format:/%Cblue%ad%Creset'
    -z
    "$@"
  )

  declare -A -- COUNTS=() TIMES=()

  TMP="$(mktemp)"
  "${ARGV[@]}" > "$TMP"

  while read -d '' -r LINE; do
    while :; do
      case "$LINE" in
      /*)
        TIME="${LINE%%$'\n'*}"
        LINE="${LINE#*$'\n'}"
        if [[ $TIME == "$LINE" ]]; then
          LINE=''
          break
        fi
        ;;
      *)
        break
        ;;
      esac
    done

    if [[ -z $LINE ]]; then
      continue
    fi

    TIME="${TIME#*/}"
    TIMES["$LINE"]="$TIME"
    COUNT="${COUNTS["$LINE"]:-0}"
    COUNTS["$LINE"]="$((COUNT + 1))"
  done < "$TMP"

  rm -f -- "$TMP"

  for LINE in "${!COUNTS[@]}"; do
    COUNT="${COUNTS["$LINE"]}"
    TIME="${TIMES["$LINE"]}"
    printf -- '%s %s\n%s\0' "$COUNT" "$TIME" "$LINE"
  done | sort --zero-terminated --key 1 --numeric-sort --reverse | "${0%/*}/../libexec/fzf-lr.sh" "$0"
  ;;
esac
