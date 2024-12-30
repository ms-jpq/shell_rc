#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

# shellcheck disable=SC2154
exec -- "${0%/*}/../libexec/mbsync.sh" "$AERC_ACCOUNT:$AERC_FOLDER"
