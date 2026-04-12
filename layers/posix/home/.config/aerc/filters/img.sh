#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

C="$COLUMNS"

exec -- catimg -w $((COLS * 2 - 2)) -
