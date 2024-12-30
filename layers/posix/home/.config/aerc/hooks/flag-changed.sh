#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

# shellcheck disable=SC2154
ACCOUNT="${AERC_ACCOUNT#'<'}"
ACCOUNT="${ACCOUNT%'>'}"
ACCOUNT="${ACCOUNT,,}"

# shellcheck disable=SC2154
"${0%/*}/../libexec/mbsync.sh" "$ACCOUNT:$AERC_FOLDER" &
