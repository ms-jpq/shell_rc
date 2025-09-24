#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail


FILE="$1"
shift -- 1

exec -- rg "$@" "$FILE"
