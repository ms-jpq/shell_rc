#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

: "${AERC_ACCOUNT?}"

exec -- touch -- ~/.local/state/isync/mbsync."$AERC_ACCOUNT".queue/trigger
