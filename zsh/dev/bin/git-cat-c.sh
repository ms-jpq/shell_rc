#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

case "${SCRIPT_MODE:-""}" in
preview)
  readarray -t -d '' -- LINES
  git show --relative "$@" -- "${LINES[@]}" | ${GIT_PAGER:-delta}
  ;;
execute)
  readarray -t -d '' -- LINES
  printf -- '%q\n' "${LINES[@]}"
  ;;
*)
  ARGV=(
    git show
    --relative
    --name-only
    --format=''
    -z
    "$@"
  )
  "${ARGV[@]}" | "${0%/*}/../libexec/fzf-lr.sh" "$0" "$@"
  ;;
esac
