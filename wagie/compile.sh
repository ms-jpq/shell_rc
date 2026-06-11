#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

OUT="$1"

SELF="${0%/*}"
HOME_LAYER=./layers/posix/home
CONFIG="$OUT/config"
LOCAL="$OUT/local"
STUB="$OUT/layers/posix/home"

rm -fr -- "$OUT"
mkdir -p -- "$CONFIG" "$LOCAL" "$STUB"

CP=(cp -a -f --)
COPIES=(
  "$HOME_LAYER/.config/." "$CONFIG/"
  "$HOME_LAYER/.zshenv" "$OUT/zshenv"
  "$SELF/link.sh" "$OUT/"
  ./libexec/zsh.sh "$OUT/"
  ./zsh "$OUT/zsh"
)

for ((I = 0; I < ${#COPIES[@]}; I += 2)); do
  "${CP[@]}" "${COPIES[I]}" "${COPIES[I + 1]}"
done

COPIES=(
  bin
  lbin
  libexec
  lprofile.d
)
for NAME in "${COPIES[@]}"; do
  "${CP[@]}" "$HOME_LAYER/.local/$NAME" "$LOCAL/$NAME"
done

ln -snf -- /dev/null "$STUB/.zshenv"
rm -fr -- "$CONFIG/tmux/sessions" "$CONFIG/pip"/*
