#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

case "${SCRIPT_MODE:-""}" in
preview)
  readarray -t -d '' -- LINES
  for LINE in "${LINES[@]}"; do
    FILE="${LINE#*' '}"
    printf -- '%s\0' "$FILE"
  done | xargs -r -0 -- git diff --relative "$@" -- | ${GIT_PAGER:-delta}
  ;;
execute)
  readarray -t -d '' -- LINES
  for LINE in "${LINES[@]}"; do
    FILE="${LINE#*' '}"
    printf -- '%q\n' "$FILE"
  done
  ;;
*)
  ARGV=(
    git diff
    --relative
    --name-status
    -z
    "$@"
  )

  HEAD=1
  DOUBLE=0
  "${ARGV[@]}" | while read -d '' -r LINE; do
    if ((HEAD)); then
      HEAD=0
      STAT="$LINE"
      case "$LINE" in
      R*)
        DOUBLE=1
        ;;
      *) ;;
      esac
      continue
    else
      if ((DOUBLE)); then
        DOUBLE=0
      else
        HEAD=1
      fi
      printf -- '%s\0' "$STAT $LINE"
    fi
  done | "${0%/*}/../libexec/fzf-lr.sh" "$0" "$@"
  ;;
esac
