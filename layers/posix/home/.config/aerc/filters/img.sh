#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

C="$COLUMNS"
exec -- catimg -w $((C * 2 - 2)) -
