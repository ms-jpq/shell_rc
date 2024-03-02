#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

PORT=8080
printf -- '%s\n' "http://$HOSTNAME:$PORT/"
exec -- rclone --config /dev/null --copy-links serve http --addr "[::]:$PORT" "$@"
