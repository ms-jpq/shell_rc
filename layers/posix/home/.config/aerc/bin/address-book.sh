#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

CACHE=~/.cache/maildir

if [[ ! -d $CACHE ]]; then
  mkdir -p -- "$CACHE"
fi

QUERY="$1"
shift -- 1

GREP=(
  grep
  --binary-files text
  --no-filename
  --ignore-case
  --fixed-strings
  -- "$QUERY"
)
if (($#)); then
  GREP+=("$CACHE/addr.$*.txt")
else
  GREP+=("$CACHE"/addr.*.txt)
fi

"${GREP[@]}" < /dev/null | cut -d $'\t' -f 2-
