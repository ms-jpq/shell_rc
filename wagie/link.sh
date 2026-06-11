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
for NAME in *; do
  DST=~/.config/"$NAME"
  if [[ $NAME == nvim ]]; then
    rsync --archive --exclude=/init.lua -- "$PWD/$NAME/" "$DST"
  else
    ln -snf -- "$PWD/$NAME" "$DST"
  fi
done

rsync --archive -- "$SRC/config.d/" ~/.config/
rsync --archive -- "$SRC/local/" ~/.local/
rsync --archive -- "$SRC/local.d/" ~/.local/
