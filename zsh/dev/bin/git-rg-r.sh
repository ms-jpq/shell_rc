#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

parse() {
  LINE="$(</dev/stdin)"
  POINTER="${LINE%% *}"
}

SEARCH=()
for RE in "$@"; do
  SEARCH+=(-G "$RE")
done

case "${SCRIPT_MODE:-""}" in
preview)
  parse
  git show "$POINTER" "${SEARCH[@]}" | delta
  ;;
execute)
  parse
  printf -- '%q\n' "$POINTER"
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
    "${SEARCH[@]}"
  )
  "${ARGV[@]}" | "${0%/*}/../libexec/fzf-lr.sh" "$0" "$@"
  ;;
esac
