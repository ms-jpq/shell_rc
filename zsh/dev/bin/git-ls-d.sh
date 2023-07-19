#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

parse() {
  LINE="$(</dev/stdin)"
  SHA="${LINE%% *}"
  FILE="${LINE##* }"
}

case "${SCRIPT_MODE:-""}" in
preview)
  parse
  git show --relative "$SHA^:$FILE" | bat --color always --file-name "$FILE"
  ;;
execute)
  parse
  printf -- '%q\n' "$SHA^:$FILE"
  ;;
*)
  ARGV=(
    git log
    --relative
    --all
    --diff-filter=D
    --name-only
    --pretty='format:%Cgreen%h%Creset %Cblue%ad%Creset'
    -z
    "$@"
  )
  HEAD=1
  "${ARGV[@]}" | while read -d $'\0' -r LINE; do
    if [[ -z "$LINE" ]]; then
      HEAD=1
      continue
    fi
    if ((HEAD)); then
      SHA="${LINE%% *}"
      LINE="${LINE##*$'\n'}"
      HEAD=0
    fi
    printf -- '%s\0' "$SHA $LINE"
  done | "${0%/*}/../libexec/fzf-lr.sh" "$0"
  ;;
esac
