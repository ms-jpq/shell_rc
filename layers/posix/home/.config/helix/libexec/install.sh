#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

SCRIPT="$1"
DIR="$(realpath -- "$0")"
DIR="$(dirname -- "$DIR")"

RT="$HOME/.cache/helix-rt"
ROOT="$RT/more/${SCRIPT//'/'/-}"
TMP="$(mktemp -d --tmpdir "$ROOT/tmp")"

export -- BIN="$ROOT/bin" LIB="$ROOT/LIB" TMP TMPDIR="$TMP"
PATH="$DIR:$PATH"

CODE=0
pushd -- "$TMP"
$"${0%/*}/cond-exec.sh" "$DIR/../install/$SCRIPT" || CODE="$?"
popd
rm -fr -- "$TMP"
exit "$CODE"
