#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

# shellcheck disable=SC2206
RSH=($1)

SRC="$2"
DST="$3"
REMOTE="${DST%%:*}"
SINK="${DST#*:}"

tar -c -C "$SRC" -- . | "${RSH[@]}" "$REMOTE" tar -x -p -C "$SINK"
