#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

# shellcheck disable=SC2154
CHANNEL="${AERC_ACCOUNT#'<'}"
CHANNEL="${CHANNEL%'>'}"
CHANNEL="${CHANNEL,,}"

exec -- touch -- ~/.local/state/isync/mbsync."$CHANNEL".watch/trigger
