#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

cd -- ~

mkdir -v -p -- "$HOME/.local"

link() {
  local -- src="$1" dst="$2"

  if ! [[ -f "$dst" ]]; then
    ln -v -sf -- "$src" "$dst"
  fi
}

# shellcheck disable=2154
link "$APPDATA" "$HOMEPATH/.config"
# shellcheck disable=2154
link "$LOCALAPPDATA" "$HOMEPATH/.local/share"
link "${LOCALAPPDATA}Low" "$HOMEPATH/.local/state"
link "$LOCALAPPDATA/Temp" "$HOMEPATH/.cache"

# link "$HOME/AppData/LocalHigh" "$HOMEPATH/.local/opt"
