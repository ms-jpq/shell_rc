#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

USERPROFILE="${USERPROFILE:-"$HOME"}"
APPDATA="${APPDATA:-"$USERPROFILE/AppData/Roaming"}"
LOCALAPPDATA="${LOCALAPPDATA:-"$USERPROFILE/AppData/Local"}"
TEMP="${TEMP:-"$LOCALAPPDATA/Temp"}"
LOCALLO="$HOME/AppData/LocalLow"
LOCALHI="$HOME/AppData/LocalHigh"

mkdir -v -p -- "$USERPROFILE/.local" "$APPDATA" "$LOCALAPPDATA" "$TEMP" "$LOCALLO" "$LOCALHI"

link() {
  local -- src="$1" dst="$2"

  if ! [[ -d "$dst" ]]; then
    ln -v -sf -- "$src" "$dst" || true
  fi
}

link "$USERPROFILE/.ignore" "$USERPROFILE/.fdignore"
link "$APPDATA" "$USERPROFILE/.config"
link "$LOCALAPPDATA" "$USERPROFILE/.local/share"
link "$TEMP" "$USERPROFILE/.cache"
link "$LOCALLO" "$USERPROFILE/.local/state"
link "$LOCALHI" "$USERPROFILE/.local/opt"
