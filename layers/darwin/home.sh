#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

SCRIPT="$HOME/Library/Script Libraries"
mkdir -v -p -- "$HOME/.local" "$SCRIPT"

link() {
  local -- src="$1" dst="$2"

  if ! [[ -L "$dst" ]]; then
    ln -v -sf -- "$src" "$dst"
  fi
}

link "$HOME/Applications" "$HOME/.local/opt"
link "$HOME/Library/Application Support" "$HOME/.local/share"
link "$HOME/Library/Caches" "$HOME/.cache"
link "$HOME/Library/Caches" "$HOME/.local/state"
link "$HOME/Library/Preferences" "$HOME/.config"
link "$SCRIPT" "$HOME/.local/scripts"
