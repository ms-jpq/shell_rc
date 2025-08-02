#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

ARG0="$0"

if [[ -x $ARG0 ]]; then
  BANG="$(sed -E -n -e '1s@^#!([^ ]+).*$@\1@p' -- "$ARG0")"
  if [[ $BANG == '/usr/bin/env' ]]; then
    BANG="$(sed -E -n -e '1s@^#!/usr/bin/env( {1,}-{1,2}\w+ {1,})(-- {1,})?(\w+).*$@\3@p' -- "$ARG0")"
  fi
fi

if ! command -v -- "$ARG0"; then
  exec -- tee <<- EOF
! command -v -- $ARG0
EOF
fi

echo exec -- "$@"
