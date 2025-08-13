#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

SCRIPT="$1"
DIR="$(realpath -- "$0")"
DIR="$(dirname -- "$DIR")"
NAME="${SCRIPT//"/"/-}"

case "$OSTYPE" in
linux* | darwin*)
  VAR="/var/tmp/helix-rt"
  ;;
msys)
  # shellcheck disable=SC2154
  VAR="$TEMP/helix-rt/var"
  ;;
*)
  set -v
  exit 1
  ;;
esac
RT="$HOME/.cache/helix-rt"

ROOT="$RT/more/$NAME"
BIN="$ROOT/bin"
LIB="$ROOT/lib"

mkdir -p -- "$VAR" "$ROOT"
TMP="$(mktemp -d -p "$VAR" "$NAME.XXXXXX")"

export -- BIN LIB TMP TMPDIR="$TMP"
CODE=0
pushd -- "$VAR" > /dev/null
"$DIR/cond-exec.sh" "$DIR/../install/$SCRIPT" || CODE="$?"
popd > /dev/null
rm -fr -- "$TMP"
exit "$CODE"
