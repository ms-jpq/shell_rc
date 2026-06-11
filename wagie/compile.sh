#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

OUT="$1"

SELF="${0%/*}"
HOME_LAYER=./layers/posix/home
CONFIG="$OUT/config"
ZOUT="$CONFIG/zsh"

case "$OSTYPE" in
darwin*)
  OS=darwin
  ;;
linux*)
  OS=ubuntu
  ;;
msys | cygwin)
  OS=nt
  ;;
*)
  set -v
  exit 2
  ;;
esac

rm -fr -- "$OUT"
mkdir -p -- "$CONFIG"
env -C "$SELF/.." -- ./libexec/zsh.sh "$OS" "$ZOUT" "$OUT"

CP=(cp -a -f --)
COPIES=(
  "$HOME_LAYER/.config/." "$CONFIG/"
  "$HOME_LAYER/.zshenv" "$OUT/zshenv"
  "$SELF/link.sh" "$OUT/"
  ./libexec/zsh.sh "$OUT/"
  ./zsh "$ZOUT"
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
  "${CP[@]}" "$HOME_LAYER/.local/$NAME" "$OUT/local/$NAME"
done

rm -fr -- "$CONFIG/tmux/sessions" "$CONFIG/pip"/*
