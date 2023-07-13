#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

if [[ $# -lt 2 ]]; then
  printf >&2 -- '%s\n' 'ERROR -- missing args:
  <search> <replacement>'
  exit 1
fi

if [[ -t 0 ]]; then
  printf >&2 -- '%s\n' 'ERROR -- nil stdin'
  exit 1
fi

SEARCH="$1"
REPLACE="$2"
shift
shift

ARGS=(
  --replace
  "$REPLACE"
  "$@"
  --color=never
  --passthru
  --
  "$SEARCH"
)

exec -- rg "${ARGS[@]}" </dev/stdin
