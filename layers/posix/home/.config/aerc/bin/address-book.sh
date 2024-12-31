#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

CACHE=~/.cache/maildir

if [[ ! -d $CACHE ]]; then
  mkdir -p -- "$CACHE"
fi

if (($# > 1)); then
  CACHED=("$CACHE/addr.$1.txt")
  shift -- 1
  QUERY="$*"
else
  CACHED=("$CACHE"/addr.*.txt)
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

cut -d ' ' -f 3- -- "${CACHED[@]}" < /dev/null | "${GREP[@]}"
