#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

cd -- ~

HOMEPATH="${HOMEPATH:-"$HOME"}"
APPDATA="${APPDATA:-"$HOMEPATH/AppData/Roaming"}"
LOCALAPPDATA="${LOCALAPPDATA:-"$HOMEPATH/AppData/Local"}"
TEMP="${TEMP:-"$LOCALAPPDATA/Temp"}"

mkdir -v -p -- "$HOMEPATH/.local"

link() {
  local -- src="$1" dst="$2"

  if ! [[ -L "$dst" ]]; then
    ln -v -sf -- "$src" "$dst" || true
  fi
}

link "$APPDATA" "$HOMEPATH/.config"
link "$LOCALAPPDATA" "$HOMEPATH/.local/share"
link "${LOCALAPPDATA}Low" "$HOMEPATH/.local/state"
link "$TEMP" "$HOMEPATH/.cache"
LOCALHI="$HOME/AppData/LocalHigh"
mkdir -v -p -- "$LOCALHI"
link "$LOCALHI" "$HOMEPATH/.local/opt"
