#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

cd -- ~

mkdir -p -- "$HOME/.local"

link() {
  local -- src="$1" dst="$2"

  if ! [[ -L "$dst" ]]; then
    ln -sf -- "$src" "$dst"
  fi
}

link "$HOME/AppData/Local" "$HOME/.local/share"
link "$HOME/AppData/LocalHigh" "$HOME/.local/opt"
link "$HOME/AppData/LocalLow" "$HOME/.cache"
link "$HOME/AppData/LocalLow" "$HOME/.local/state"
link "$HOME/AppData/Roaming" "$HOME/.config"
