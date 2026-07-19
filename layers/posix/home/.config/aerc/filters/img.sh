#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

COLUMNS=${COLUMNS:-"$(stty size < /dev/tty | cut -d ' ' -f 2)"}
exec -- catimg -w $((COLUMNS * 2 - 2)) -
