#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

SCRIPT="$1"
DIR="$(realpath -- "$0")"
DIR="$(dirname -- "$DIR")"

PATH="$DIR:$HOME/.local/opt/initd/libexec:$PATH"
RT="$HOME/.cache/helix-rt"
VAR="$RT/var"
VAR_TMP="$RT/tmp"
NAME="${SCRIPT//'/'/-}"
ROOT="$RT/more/$NAME"
BIN="$ROOT/bin"
LIB="$ROOT/LIB"

mkdir -p -- "$VAR" "$BIN" "$VAR_TMP"
TMP="$(mktemp -d -p "$VAR_TMP" "$NAME.XXXXXX")"

export -- BIN LIB TMP TMPDIR="$TMP"
CODE=0
pushd -- "$VAR" > /dev/null
"$DIR/cond-exec.sh" "$DIR/../install/$SCRIPT" || CODE="$?"
popd > /dev/null
rm -fr -- "$TMP"
exit "$CODE"
