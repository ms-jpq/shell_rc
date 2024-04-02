#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

SRC="$2"
DST="$3"
REMOTE="${DST%%:*}"
SINK="$(sed -E -e 's#:\\#:\\\\#' <<<"${DST#*:}")"

if [[ "$REMOTE" == 'localhost' ]]; then
  RSH=()
else
  # shellcheck disable=SC2206
  RSH=($1 "$REMOTE")
  SINK="\"$SINK\""
fi

tar -c -C "$SRC" -- . | "${RSH[@]}" tar -x -p -C "$SINK"
