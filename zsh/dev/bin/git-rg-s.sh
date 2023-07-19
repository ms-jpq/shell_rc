#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

parse() {
  LINE="$(</dev/stdin)"
  SHA="${LINE%% *}"
}

case "${SCRIPT_MODE:-""}" in
preview)
  parse
  git show "$SHA" "$@" | delta
  ;;
execute)
  parse
  printf -- '%q\n' "$SHA"
  ;;
*)
  SEARCH=()
  for RE in "$@"; do
    SEARCH+=(-G "$RE")
  done
  ARGV=(
    git log
    --relative
    --all
    --pretty='format:%Cgreen%h%Creset %Cblue%ad%Creset %s'
    -z
    "${SEARCH[@]}"
  )
  "${ARGV[@]}" | "${0%/*}/../libexec/fzf-lr.sh" "$0" "${SEARCH[@]}"
  ;;
esac
