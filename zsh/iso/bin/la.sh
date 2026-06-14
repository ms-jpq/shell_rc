#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

case "$OSTYPE" in
darwin*)
  export -- LC_ALL=en_CA.UTF-8
  ;;
*)
  export -- LC_ALL=en_US.UTF-8
  ;;
esac

exec -- lazygit "$@"
