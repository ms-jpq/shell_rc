#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

declare -A -- LINKS=()
LINKS=(
  ["$HOME/.config/systemd/user/gpg-agent.service"]=/dev/null
  ["$HOME/.config/systemd/user/gpg-agent.socket"]=/dev/null
  ["$HOME/.gnupg"]="$HOME/.config/gnupg"
)

for FROM in "${!LINKS[@]}"; do
  TO="${LINKS["$FROM"]}"
  if ! [[ -L "$FROM" ]]; then
    ln -v -sf -- "$TO" "$FROM"
  fi
done
