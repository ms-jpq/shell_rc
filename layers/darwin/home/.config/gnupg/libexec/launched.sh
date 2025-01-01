#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob

set -o pipefail

ARGV=(
  /opt/homebrew/bin/gpg-agent
  --batch
  --daemon "${0%/*}/sleep.sh"
)

"${ARGV[@]}" 2>&1 | logger -t org.gnupg.gpg-agent
