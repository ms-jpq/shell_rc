#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

OPTS=''
LONG_OPTS='auth,network,path:'
GO="$(getopt --options="$OPTS" --longoptions="$LONG_OPTS" --name="$0" -- "$@")"
eval -- set -- "$GO"

AUTH=0
NETWORK=0
FILESYSTEM=()
while true; do
  case "$1" in
  --auth)
    AUTH=1
    shift -- 1
    ;;
  --network)
    NETWORK=1
    shift -- 1
    ;;
  --path)
    FILESYSTEM+=("$2")
    shift -- 2
    ;;
  --)
    shift -- 1
    break
    ;;
  *)
    set -x
    exit 2
    ;;
  esac
done

ROOT="$(realpath -- "${0%/*}/..")"

ARGV=(
  sandbox-exec
  -D PROFILES="$ROOT/darwin"
  -D TMPDIR="$TMPDIR"
  -D HOME="$HOME"
  -D CWD="$PWD"
)

PROFILES=(
  '(import (string-append (param "PROFILES") "/0-cli.sb"))'
)

if ((AUTH)); then
  # shellcheck disable=SC2154
  ARGV+=(-D SSH_AUTH_SOCK="$SSH_AUTH_SOCK")
  PROFILES+=('(import-profile "1-auth.sb")')
fi

if ((NETWORK)); then
  PROFILES+=('(import-profile "1-network.sb")')
fi

for _ in "${FILESYSTEM[@]}"; do
  :
done

IFS=$'\n'
PROFILE="${PROFILES[*]}"
unset -- IFS
ARGV+=(-p "$PROFILE")

exec -- "${ARGV[@]}" -- "$@"
