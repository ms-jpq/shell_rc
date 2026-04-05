#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

COLS="$(stty size < /dev/tty | cut -d ' ' -f 2)"

exec -- catimg -w $((COLS * 2 - 2)) -
