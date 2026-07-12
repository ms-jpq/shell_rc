#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

case "$OSTYPE" in
darwin*)
  SHARE='/opt/homebrew/share'
  ;;
*)
  SHARE='/usr/share'
  ;;
esac

RUN="$SHARE/neomutt/oauth2/mutt_oauth2.py"
OAUTH=(/opt/homebrew/bin/python3 "$RUN")

exec -- "${OAUTH[@]}" "$@"
