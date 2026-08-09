#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

OUT="$1"

SELF="${0%/*}"
HOME_LAYER=./layers/posix/home
DARWIN_LAYER=./layers/darwin/home
CONFIG="$OUT/config"
LOCAL="$OUT/local"
STUB="$OUT/layers/posix/home"
CACHE="$OUT/cache"
SNIPS="$HOME/.cache/helix-rt/nvim/pack/opt/snips"

rm -fr -- "$OUT"
mkdir -p -- "$CACHE" "$CONFIG" "$LOCAL" "$STUB"

CP=(cp -a -f --)
COPIES=(
  "$HOME_LAYER/.config/." "$CONFIG/"
  "$DARWIN_LAYER/.config/hammerspoon" "$CONFIG/"
  "$HOME_LAYER/.zshenv" "$OUT/zshenv"
  "$SELF/link.sh" "$OUT/"
  ./libexec/zsh.sh "$OUT/"
  ./zsh "$OUT/zsh"
)

for ((I = 0; I < ${#COPIES[@]}; I += 2)); do
  "${CP[@]}" "${COPIES[I]}" "${COPIES[I + 1]}"
done

rsync --archive --exclude='.git' -- "$SNIPS/" "$CACHE/helix-rt/nvim/pack/opt/snips/"

COPIES=(
  bin
  lbin
  libexec
  lprofile.d
)
for NAME in "${COPIES[@]}"; do
  "${CP[@]}" "$HOME_LAYER/.local/$NAME" "$LOCAL/$NAME"
done

ln -sTnf -- /dev/null "$STUB/.zshenv"

BIN="$OUT/bin-link" "$CONFIG/helix/install/bin-link.sh"

rm -fr -- "$CONFIG/tmux/sessions"
