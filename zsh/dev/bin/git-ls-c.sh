#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

case "${SCRIPT_MODE:-""}" in
preview)
  readarray -t -d '' -- LINES
  for LINE in "${LINES[@]}"; do
    SHA="${LINE%% *}"
    git show "$SHA" "$@"
  done | ${GIT_PAGER:-delta}
  ;;
execute)
  readarray -t -d '' -- LINES
  for LINE in "${LINES[@]}"; do
    SHA="${LINE%% *}"
    printf -- '%q\n' "$SHA"
  done
  ;;
*)
  ARGV=(
    git log
    --relative
    --all
    --color --pretty='format:%Cgreen%h%Creset %Cblue%ad%Creset %s'
    -z
    "$@"
  )
  "${ARGV[@]}" | "${0%/*}/../libexec/fzf-lr.sh" "$0" "$@"
  ;;
esac
