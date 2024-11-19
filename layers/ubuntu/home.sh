#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

SYSTEMD="$HOME/.config/systemd/user"

declare -A -- LINKS=()
LINKS=(
  ["$HOME/.gnupg"]="$HOME/.config/gnupg"
  ["$SYSTEMD/gpg-agent-browser.socket"]=/dev/null
  ["$SYSTEMD/gpg-agent-extra.socket"]=/dev/null
  ["$SYSTEMD/gpg-agent-ssh.socket"]=/dev/null
  ["$SYSTEMD/gpg-agent.service"]=/dev/null
  ["$SYSTEMD/gpg-agent.socket"]=/dev/null
)

for FROM in "${!LINKS[@]}"; do
  TO="${LINKS["$FROM"]}"
  if ! [[ -L $FROM ]]; then
    mkdir -v -p -- "${FROM%/*}"
    ln -v -snf -- "$TO" "$FROM"
  fi
done
