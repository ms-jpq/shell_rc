#!/usr/bin/env -S -- bash

set -Eeu
set -o pipefail
shopt -s dotglob nullglob extglob globstar

OUT="$1"

SELF="${0%/*}"
HOME_LAYER=./layers/posix/home
CONFIG="$OUT/config"
ZOUT="$OUT/zsh"

rm -fr -- "$OUT"
mkdir -p -- "$CONFIG"

CP=(cp -a -f --)

COPIES=(
  "$HOME_LAYER/.zshenv" "$OUT/zshenv"
  "$SELF/z-compile.sh" "$OUT/"
  ./libexec/zsh.sh "$OUT/"
  ./zsh "$ZOUT"
)

for ((I = 0; I < ${#COPIES[@]}; I += 2)); do
  "${CP[@]}" "${COPIES[I]}" "${COPIES[I + 1]}"
done

"${CP[@]}" "$HOME_LAYER/.config"/* "$CONFIG"
"${CP[@]}" "$SELF/.gitignore" "$CONFIG/"

rm -fr -- "$CONFIG/tmux/sessions"
