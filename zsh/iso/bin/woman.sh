#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail
set -x

TMP="$(mktemp -d)/index.html"

PR="$(command -v -- man2html)"

case "$OSTYPE" in
darwin*)
  PR="$(printf -- '%q ' perl -CASD "$PR" -compress -title "MAN - $*")"
  ;;
*) ;;
esac
man -P "$PR" -- "$*" </dev/null >"$TMP"

if command -v -- open >/dev/null; then
  exec -- open "$TMP"
else
  TMP="${TMP%/*}"
  printf -- '%q\n' "$TMP" >&2
  exec -- "${0%/*}/srv" -- "$TMP"
fi
