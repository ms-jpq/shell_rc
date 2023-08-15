#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

read -r -d '' -- SCRIPT

jq "$SCRIPT" "$@" || true

exec -- "$0" "$@"
