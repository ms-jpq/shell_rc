#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

COLUMNS=${COLUMNS:-"$(tput cols)"}
exec -- catimg -w $((COLUMNS * 2 - 2)) -
