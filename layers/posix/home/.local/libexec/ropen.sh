#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

: "${XDG_RUNTIME_DIR?}"

SOCK="$XDG_RUNTIME_DIR/ropen.sock"

if [[ ${RECUR:-} == 1 ]]; then
  while IFS= read -r -d '' TARGET; do
    case "$TARGET" in
    http://?* | https://?*)
      open -- "$TARGET"
      ;;
    *)
      ;;
    esac
  done
elif [[ -n ${SSH_CONNECTION:-} ]]; then
  : "${1?}"
  printf -- '%s\0' "$@" | socat - "UNIX-CONNECT:$SOCK"
else
  export -- RECUR=1
  exec -- socat "UNIX-LISTEN:$SOCK,unlink-early,fork,mode=0600" "EXEC:\"$0\""
fi
