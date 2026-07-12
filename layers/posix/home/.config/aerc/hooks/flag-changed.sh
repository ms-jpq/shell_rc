#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

# shellcheck disable=SC2154
exec -- touch -- ~/.local/state/isync/mbsync."$AERC_ACCOUNT".watch/trigger
