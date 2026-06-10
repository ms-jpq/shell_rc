#!/usr/bin/env -S -- bash

set -Eeu
set -o pipefail
shopt -s dotglob nullglob extglob failglob

cd -- "${0%/*}"

case "$OSTYPE" in
darwin*) OS=darwin ;;
linux*) OS=ubuntu ;;
msys | cygwin) OS=nt ;;
*)
  set -v
  exit 2
  ;;
esac

exec -- ./zsh.sh "$OS" ./config/zsh .
