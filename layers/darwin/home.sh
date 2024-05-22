#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

SCRIPT="$HOME/Library/Script Libraries"
mkdir -v -p -- "$SCRIPT"

declare -A -- LINKS=()
LINKS=(
  ["$HOME/.cache"]="$HOME/Library/Caches"
  ["$HOME/.config"]="$HOME/Library/Preferences"
  ["$HOME/.local/opt"]="$HOME/Applications"
  ["$HOME/.local/scripts"]="$SCRIPT"
  ["$HOME/.local/share"]="$HOME/Library/Application Support"
)

for FROM in "${!LINKS[@]}"; do
  TO="${LINKS["$FROM"]}"
  if ! [[ -L $FROM ]]; then
    mkdir -v -p -- "${FROM%/*}"
    ln -v -sf -- "$TO" "$FROM"
  fi
done
