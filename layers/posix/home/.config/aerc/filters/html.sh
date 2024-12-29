#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

COLS="$(stty size < /dev/tty | cut -d' ' -f2)"
exec -- pandoc --read=html --write=plain --columns=$((COLS - 2))
