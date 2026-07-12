#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

ARG0="$1"

ASDF_DATA_DIR="$HOME/.local/asdf"
if [[ -d $ASDF_DATA_DIR ]]; then
  PATH="$ASDF_DATA_DIR/shims:$PATH"
  export -- ASDF_CONFIG_FILE="$HOME/.config/asdf/rc.conf" ASDF_DATA_DIR
fi

if [[ -x $ARG0 ]]; then
  BANG="$(sed -E -n -e '1s@^#!([^ ]+).*$@\1@p' -- "$ARG0")"
  if [[ $BANG == '/usr/bin/env' ]]; then
    ARG0="$(sed -E -n -e '1s@^#!/usr/bin/env( {1,}-{1,2}[[:alnum:]]+ {1,})(-- {1,})?([[:alnum:]]+=[[:alnum:]]* *)*([[:alnum:]]+).*$@\4@p' -- "$ARG0")"
  elif [[ -z $BANG ]]; then
    ARG0="$(sed -E -n -e '1s@^// *; *exec *([[:alnum:]]+).*$@\1@p' -- "$ARG0")"
  fi
fi

if ! command -v -- "$ARG0" > /dev/null; then
  exec -- tee <<- EOF >&2
! command -v -- $ARG0
EOF
fi

exec -- "$@"
