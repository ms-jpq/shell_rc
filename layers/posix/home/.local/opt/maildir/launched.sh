#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

LABEL="mnotify.$1"

{
  printf -- '%s\n' "$@"
} 2>&1 | logger -t "$LABEL"
