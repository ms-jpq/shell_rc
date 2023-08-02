#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

if command -v -- cygpath >/dev/null; then
  cygpath --unix -- ~
else
  printf -- '%s' ~
fi
