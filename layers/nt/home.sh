#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

HOMEPATH="${HOMEPATH:-"$HOME"}"
APPDATA="${APPDATA:-"$HOMEPATH/AppData/Roaming"}"
LOCALAPPDATA="${LOCALAPPDATA:-"$HOMEPATH/AppData/Local"}"
TEMP="${TEMP:-"$LOCALAPPDATA/Temp"}"
LOCALLO="$HOME/AppData/LocalLow"
LOCALHI="$HOME/AppData/LocalHigh"

mkdir -v -p -- "$HOMEPATH/.local" "$APPDATA" "$LOCALAPPDATA" "$TEMP" "$LOCALLO" "$LOCALHI"

link() {
  local -- src="$1" dst="$2"

  if ! [[ -d "$dst" ]]; then
    ln -v -sf -- "$src" "$dst"
  fi
}

link "$APPDATA" "$HOMEPATH/.config"
link "$LOCALAPPDATA" "$HOMEPATH/.local/share"
link "$TEMP" "$HOMEPATH/.cache"
link "$LOCALLO" "$HOMEPATH/.local/state"
link "$LOCALHI" "$HOMEPATH/.local/opt"
