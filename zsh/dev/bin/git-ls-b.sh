#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

SCRIPT_MODE="${SCRIPT_MODE:-""}"

case "${SCRIPT_MODE:-""}" in
execute)
  FILE="$(</dev/stdin)"
  printf -- '%q\n' "$FILE"
  git blame -w -- "$FILE" | delta "$@"
  ;;
preview)
  git blame -w -- "$(</dev/stdin)" | delta "$@"
  ;;
*)
  git ls-files --recurse-submodules -z | "${0%/*}/../libexec/fzf-lr.sh" "$0" "$@"
  ;;
esac
