#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

SRC="$2"
DST="$3"
REMOTE="${DST%%:*}"
SINK="${DST#*:}"

# shellcheck disable=SC1003
if [[ "$REMOTE" == 'localhost' ]]; then
  PATH="/usr/bin:$PATH"
  RSH=()
  TAR='tar'
  SINK="$(cygpath --absolute --mixed --windows "$SINK")"
else
  # shellcheck disable=SC2206
  RSH=($1 "$REMOTE")
  TAR='"%PROGRAMFILES%\Git\usr\bin\tar"'
  SINK="\"$SINK\""
fi

tar --create --directory "$SRC" -- . | "${RSH[@]}" "$TAR" --extract --preserve-permissions --keep-directory-symlink --directory "$SINK"
