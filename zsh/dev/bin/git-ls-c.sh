#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

case "${SCRIPT_MODE:-""}" in
preview)
  LINE="$(</dev/stdin)"
  SHA="${LINE%% *}"
  git show "$SHA" | delta
  ;;
execute)
  LINE="$(</dev/stdin)"
  SHA="${LINE%% *}"
  printf -- '%q\n' "$SHA"
  ;;
*)
  ARGV=(
    git
    log
    --color
    '--pretty=format:%Cgreen%h%Creset %Cblue%ad%Creset %s'
    -z
  )
  "${ARGV[@]}" | "${0%/*}/../libexec/fzf-lr.sh" "$0" "$@"
  ;;
esac
