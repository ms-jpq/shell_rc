#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

cd -- ~

# shellcheck disable=2154
mkdir -v -p -- "$HOMEPATH/.local"

link() {
  local -- src="$1" dst="$2"

  if ! [[ -L "$dst" ]]; then
    ln -v -sf -- "$src" "$dst" || true
  fi
}

# shellcheck disable=2154
link "$APPDATA" "$HOMEPATH/.config"
# shellcheck disable=2154
link "$LOCALAPPDATA" "$HOMEPATH/.local/share"
link "${LOCALAPPDATA}Low" "$HOMEPATH/.local/state"
link "$LOCALAPPDATA/Temp" "$HOMEPATH/.cache"
link "$HOME/AppData/LocalHigh" "$HOMEPATH/.local/opt"
