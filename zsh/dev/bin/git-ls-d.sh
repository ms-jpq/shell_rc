#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

case "${SCRIPT_MODE:-""}" in
preview)
  readarray -t -d '' -- LINES
  for LINE in "${LINES[@]}"; do
    SHA="${LINE%% *}"
    FILE="${LINE#*$'\n'}"
    git show --relative "$SHA^:$FILE" | bat --color always --file-name "$FILE"
  done
  ;;
execute)
  readarray -t -d '' -- LINES
  TMP="$(mktemp -d -p .)"
  for LINE in "${LINES[@]}"; do
    SHA="${LINE%% *}"
    FILE="${LINE#*$'\n'}"
    mkdir -p -- "$TMP/${FILE%/*}"
    git show --relative "$SHA^:$FILE" > "$TMP/$FILE"
  done
  ;;
*)
  ARGV=(
    git log
    --relative
    --all
    --diff-filter=D
    --name-only
    --color --pretty='format:%Cgreen%h%Creset %Cblue%ad%Creset'
    -z
    "$@"
  )
  HEAD=1
  "${ARGV[@]}" | while read -d '' -r LINE; do
    if [[ -z $LINE ]]; then
      HEAD=1
      continue
    fi
    if ((HEAD)); then
      SHA_TIME="${LINE%%$'\n'*}"
      LINE="${LINE#*$'\n'}"
      HEAD=0
    fi
    printf -- '%s\n%s\0' "$SHA_TIME" "$LINE"
  done | "${0%/*}/../libexec/fzf-lr.sh" "$0"
  ;;
esac
