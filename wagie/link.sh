#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

SRC="$(realpath -- "$1")"

ANT="${0%/*}/../var/ant"

mkdir -p -- "$SRC"
cp -a -f -- "$ANT"/. "$SRC/"
rm -fr -- "${ANT:?}"

mkdir -p -- ~/.config ~/.local/{share,state} ~/.cache

pushd -- "$SRC/config" > /dev/null
for NAME in ./*; do
  ln -snf -- "$PWD/$NAME" ~/.config/"$NAME"
done

rsync --archive -- "$SRC/local" ~/.local/
