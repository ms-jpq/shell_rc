#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

SRC="$(realpath -- "$1")"

ZOUT="$SRC/config/zsh"

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

env -C "$SRC" -- ./zsh.sh "$OS" "$ZOUT" "$SRC"

mkdir -p -- ~/.config ~/.local/share ~/.local/state/{shell_history,ssh,tmux} ~/.cache

pushd -- "$SRC/config" > /dev/null
for NAME in ./*; do
  ln -snf -- "$PWD/$NAME" ~/.config/"$NAME"
done

rsync --archive -- "$SRC/local" ~/.local/
