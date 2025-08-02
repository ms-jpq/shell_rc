#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

ARG0="$1"

if [[ -x $ARG0 ]]; then
  BANG="$(sed -E -n -e '1s@^#!([^ ]+).*$@\1@p' -- "$ARG0")"
  if [[ $BANG == '/usr/bin/env' ]]; then
    ARG0="$(sed -E -n -e '1s@^#!/usr/bin/env( {1,}-{1,2}\w+ {1,})(-- {1,})?(\w+=\w* *)*(\w+).*$@\4@p' -- "$ARG0")"
  elif [[ -z $BANG ]]; then
    ARG0="$(sed -E -n -e '1s@^// *; *exec *(\w+).*$@\1@p' -- "$ARG0")"
  fi
fi

if ! command -v -- "$ARG0"; then
  exec -- tee <<- EOF
! command -v -- $ARG0
EOF
fi

exec -- "$@"
