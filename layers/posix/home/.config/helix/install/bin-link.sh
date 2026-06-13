#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

SELF="$(realpath -- "$0")"
BASE="${SELF%/*}"
BASE="${BASE%/*}"

SRC="$BASE/bin"
# shellcheck disable=SC2154
DST="$BIN"
mkdir -p -- "$BIN"

shopt -u failglob
for F in "$SRC"/*; do
  NAME="$(basename -- "$F")"
  STEM="${NAME%.*}"
  ln -v -sTnfr -- "$F" "$DST/$STEM"
done
