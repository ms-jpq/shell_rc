#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

APP="$1"
TITLE_REGEX="$2"
WORKSPACE="$3"

read -r -d '' -- JQ <<- 'JQ' || true
.[] | select(."app-name" == $app and (."window-title" | test($re))) | ."window-id"
JQ

ID="$(aerospace list-windows --all --json | jq -e --raw-output --arg app "$APP" --arg re "$TITLE_REGEX" "$JQ")"

exec -- aerospace move-node-to-workspace --window-id "$ID" "$WORKSPACE"
