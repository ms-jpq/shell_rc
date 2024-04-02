#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

SYSTEMD="$HOME/.config/systemd/user"
mkdir -v -p -- "$SYSTEMD"

declare -A -- LINKS=()
LINKS=(
  ["$SYSTEMD/gpg-agent.service"]=/dev/null
  ["$SYSTEMD/gpg-agent.socket"]=/dev/null
  ["$HOME/.gnupg"]="$HOME/.config/gnupg"
)

for FROM in "${!LINKS[@]}"; do
  TO="${LINKS["$FROM"]}"
  if ! [[ -L "$FROM" ]]; then
    ln -v -sf -- "$TO" "$FROM"
  fi
done
