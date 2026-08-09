#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail
shopt -u failglob

: "${CHANNEL?}"

SELF="$(realpath -- "$0")"
BASE="${SELF%/*}"

"$BASE/imap_notify.py" "$@" 2>&1 | logger -t "imap_notify.$CHANNEL"
