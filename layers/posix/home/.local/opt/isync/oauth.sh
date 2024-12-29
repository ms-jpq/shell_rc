#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

case "$OSTYPE" in
darwin*)
  SHARE='/opt/homebrew/share'
  ;;
*)
  SHARE='/usr/share'
  ;;
esac

OAUTH=(
  /usr/bin/python3
  "$SHARE/neomutt/oauth2/mutt_oauth2.py"

)

exec -- "${OAUTH[@]}" "$@"
