#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

SCRIPT="$1"
DIR="$(realpath -- "$0")"
DIR="$(dirname -- "$DIR")"
NAME="${SCRIPT//'/'/-}"

PATH="$DIR:$HOME/.local/opt/initd/libexec:$PATH"
RT="$HOME/.cache/helix-rt"

VAR="$RT/var"
VAR_TMP="$RT/tmp"
ROOT="$RT/more/$NAME"
BIN="$ROOT/bin"
LIB="$ROOT/lib"

mkdir -p -- "$VAR" "$VAR_TMP" "$BIN"
TMP="$(mktemp -d -p "$VAR_TMP" "$NAME.XXXXXX")"

export -- BIN LIB TMP TMPDIR="$TMP"
CODE=0
pushd -- "$VAR" > /dev/null
"$DIR/cond-exec.sh" "$DIR/../install/$SCRIPT" || CODE="$?"
popd > /dev/null
rm -fr -- "$TMP"
if ((CODE)); then
  printf -- '%s\n' "!!! $SCRIPT" | tee --append -- "$RT/failed.log" >&2
fi
exit "$CODE"
