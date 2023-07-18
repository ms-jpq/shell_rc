#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

cd -- ~

mkdir -p -- "$HOME/.local"

ln -sf -- "$HOME/Applications" "$HOME/.local/opt"
ln -sf -- "$HOME/Library/Application Support" "$HOME/.local/share"
ln -sf -- "$HOME/Library/Caches" "$HOME/.cache"
ln -sf -- "$HOME/Library/Caches" "$HOME/.local/state"
ln -sf -- "$HOME/Library/Preferences" "$HOME/.config"
