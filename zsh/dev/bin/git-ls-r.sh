#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

case "${SCRIPT_MODE:-""}" in
preview)
  readarray -t -d '' -- LINES
  for LINE in "${LINES[@]}"; do
    POINTER="${LINE%% *}"
    git show "$POINTER" "$@"
  done | ${GIT_PAGER:-delta}
  ;;
execute)
  readarray -t -d '' -- LINES
  for LINE in "${LINES[@]}"; do
    POINTER="${LINE%% *}"
    printf -- '%q\n' "$POINTER"
  done
  ;;
*)
  ARGV=(
    git log
    --relative
    --walk-reflogs
    --remove-empty
    --color --pretty='format:%Cgreen%gD%Creset %Cblue%ad%Creset %s'
    -z
    --all-match
    "$@"
  )
  "${ARGV[@]}" | "${0%/*}/../libexec/fzf-lr.sh" "$0" "$@"
  ;;
esac
