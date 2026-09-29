#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

SRC="$(realpath -- "$1")"

ZOUT="$SRC/config/zsh"
BIN_LINK=~/.cache/helix-rt/more/bin-link.sh
RSYNC=(rsync --archive --no-perms --executability --insecure-links)

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
  set -x
  exit 2
  ;;
esac

env -C "$SRC" -- ./zsh.sh "$OS" "$ZOUT" "$SRC"

mkdir -p -- ~/.config ~/.local/share ~/.local/state/{shell_history,ssh,tmux} ~/.cache

"${RSYNC[@]}" -- "$SRC/cache/" ~/.cache/

mkdir -p -- "$BIN_LINK"
ln -sTnfr -- "$SRC/bin-link" "$BIN_LINK/bin"

pushd -- "$SRC/config" > /dev/null
for NAME in *; do
  DST=~/.config/"$NAME"
  if [[ $NAME == nvim ]]; then
    "${RSYNC[@]}" --exclude=/init.lua -- "$PWD/$NAME/" "$DST"
  elif ! [[ -L $DST ]] && ! [[ -d $DST ]]; then
    ln -sTnfr -- "$PWD/$NAME" "$DST"
  fi
done

"${RSYNC[@]}" --keep-dirlinks -- "$SRC/config.d/" ~/.config/
"${RSYNC[@]}" --keep-dirlinks -- "$SRC/local/" ~/.local/
"${RSYNC[@]}" --keep-dirlinks -- "$SRC/local.d/" ~/.local/
