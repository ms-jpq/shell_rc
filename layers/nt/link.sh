#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

cd -- ~

mkdir -p -- "$HOME/.local"

ln -sf -- "$HOME/AppData/Local" "$HOME/.local/share"
ln -sf -- "$HOME/AppData/LocalHigh" "$HOME/.local/opt"
ln -sf -- "$HOME/AppData/LocalLow" "$HOME/.cache"
ln -sf -- "$HOME/AppData/LocalLow" "$HOME/.local/state"
ln -sf -- "$HOME/AppData/Roaming" "$HOME/.config"
