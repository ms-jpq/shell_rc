#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

SELF="$(realpath -- "$0")"
BASE="${SELF%/*}"
BASE="${BASE%/*}"

SRC="$BASE/bin"
# shellcheck disable=SC2154
DST="$BIN"

shopt -u failglob
for F in "$SRC"/*; do
  NAME="$(basename -- "$F")"
  STEM="${NAME%.*}"
  install -bD -- "$F" "$DST/$STEM"
done
