#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

MAX=128

C="$(stty size < /dev/tty | cut -d ' ' -f 2)"
if ((C > MAX)); then
  C=$((MAX))
fi

colorize | pr --omit-header --omit-pagination --indent $((C / 2)) --width $((C))
