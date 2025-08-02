#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

SCRIPT="$1"
ROOT="$HOME/.cache/helix-rt/more/${SCRIPT//'/'/-}"

export -- BIN="$ROOT/bin" LIB="$ROOT/LIB" TMP="$ROOT/tmp"

exec -- "${0%/*}/cond-exec.sh" "$SCRIPT"
