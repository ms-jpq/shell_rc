#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

JUMP="$1"
DEST="$2"
shift -- 2

PORT_RE='^([^@]+)@([^:]+):?([0-9]{0,5})$'

if [[ "$JUMP" =~ $PORT_RE ]]; then
  J_USER="${BASH_REMATCH[1]}"
  J_HOST="${BASH_REMATCH[2]}"
  J_PORT="${BASH_REMATCH[3]:-443}"
else
  printf -- '-x- %s\n' "$JUMP" >&2
  exit 1
fi

if [[ "$DEST" =~ $PORT_RE ]]; then
  D_USER="${BASH_REMATCH[1]}"
  D_HOST="${BASH_REMATCH[2]}"
  D_PORT="${BASH_REMATCH[3]:-22}"
else
  printf -- '-x- %s\n' "$DEST" >&2
  exit 1
fi

PROXY_1="$(printf -- '%q ' exec openssl s_client -quiet -connect '%%h:%%p' -servername '%%h')"
PROXY_2="$(printf -- '%q ' exec ssh -o "ProxyCommand=$PROXY_1" -W '[%h]:%p' -p "$J_PORT" -l "$J_USER" -- "$J_HOST")"

exec -- ssh -o "ProxyCommand=$PROXY_2" -p "$D_PORT" -l "$D_USER" "$@" -- "$D_HOST"