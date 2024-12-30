#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

cd -- "${0%/*}"

"${0%/*}/../libexec/mbsync.sh" "$@"
exec -- aerc :connect
