#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

ROOT="$HOME/.cache/helix-rt"
PROCS="${0%/*}/../procs.json"

if ! [[ -v RECURSE ]]; then
  RECURSE=1 xargs -0 -r -- "$0"
fi

export -- BIN="$ROOT/bin" LIB="$ROOT/LIB" TMP="$ROOT/tmp"

cat -- "$PROCS"
