#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

parse() {
  LINE="$(</dev/stdin)"
  SHA="${LINE%% *}"
}

case "${SCRIPT_MODE:-""}" in
preview)
  parse
  git show "$SHA" "$@" | ${GIT_PAGER:-delta}
  ;;
execute)
  parse
  printf -- '%q\n' "$SHA"
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
