#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

: "${BIN?}"

BASE="${0%/*}/.."

SRC="$BASE/bin"
DST="$BIN"

shopt -u failglob
for F in "$SRC"/*; do
  NAME="$(basename -- "$F")"
  STEM="${NAME%.*}"
  install -bD -- "$F" "$DST/$STEM"
done
