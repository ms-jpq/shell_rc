#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

SRC="$1"
DST="$2"

D="$(dirname -- "$DST")"
S="$(realpath --no-symlinks --relative-to "$D" -- "$SRC")"

ln -snf -- "$S" "$DST"

# shellcheck disable=SC2154
exec -- lf -remote "send $id select $DST"
