#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

case "${SCRIPT_MODE:-""}" in
preview)
  readarray -t -d '' -- LINES
  LINE="${LINES[*]}"
  printf -- '%q\n\n' "$LINE"
  git blame -w -- "$LINE" | ${GIT_PAGER:-delta}
  ;;
execute)
  readarray -t -d '' -- LINES
  printf -- '%q\n' "${LINES[@]}"
  ;;
*)
  ARGV=(
    git ls-files
    --recurse-submodules
    -z
    "$@"
  )
  "${ARGV[@]}" | "${0%/*}/../libexec/fzf-lr.sh" "$0"
  ;;
esac
