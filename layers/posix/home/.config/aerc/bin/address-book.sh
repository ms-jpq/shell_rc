#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

CACHE=~/.cache/maildir

if [[ ! -d $CACHE ]]; then
  mkdir -p -- "$CACHE"
fi

if (($# > 1)); then
  CACHED=("$CACHE/$1.addr.txt")
  shift -- 1
  QUERY="$*"
else
  CACHED=("$CACHE"/*.addr.txt)
  QUERY="$1"
fi

GREP=(
  grep
  --binary-files text
  --no-filename
  --ignore-case
  --fixed-strings
  -- "$QUERY"
)

FILTER=(tee)
if [[ -t 1 ]]; then
  FILTER=(
    tv
    --color 5
    --delimiter $'\t'
    --force-all-rows
    --upper-column-width 60
  )
fi

cut -d ' ' -f 2- -- "${CACHED[@]}" < /dev/null | "${GREP[@]}" | awk -F $'\t' -- '!seen[$1]++ { print }' | "${FILTER[@]}"
