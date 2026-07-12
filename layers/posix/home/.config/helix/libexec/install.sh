#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

SCRIPT="$1"
DIR="$(realpath -- "$0")"
DIR="$(dirname -- "$DIR")"
NAME="${SCRIPT//"/"/-}"

RT="$HOME/.cache/helix-rt"

ROOT="$RT/more/$NAME"
BIN="$ROOT/bin"
LIB="$ROOT/lib"

mkdir -p -- "$ROOT"
RUN="$(mktemp -p "$TMPDIR" -d "$NAME.XXXXXX")"

export -- RUN BIN LIB
CODE=0
pushd -- "$TMPDIR" > /dev/null
"$DIR/cond-exec.sh" "$DIR/../install/$SCRIPT" || CODE="$?"
popd > /dev/null
rm -fr -- "$RUN"
exit "$CODE"
