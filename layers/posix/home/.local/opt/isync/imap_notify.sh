#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail
shopt -u failglob

SELF="$(realpath -- "$0")"
BASE="${SELF%/*}"

# shellcheck disable=SC2154
"$BASE/imap_notify.py" "$@" 2>&1 | logger -t "imap_notify.$CHANNEL"
