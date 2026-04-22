#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

OPTS=''
LONG_OPTS='auth,network,profile:,dir:,file:'
GO="$(getopt --options="$OPTS" --longoptions="$LONG_OPTS" --name="$0" -- "$@")"
eval -- set -- "$GO"

AUTH=0
NETWORK=0
USER_PROFILES=()
DIRS=()
FILES=()
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
  --profile)
    USER_PROFILES+=("$2")
    shift -- 2
    ;;
  --dir)
    DIRS+=("$2")
    shift -- 2
    ;;
  --file)
    FILES+=("$2")
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
  '(import-profile "3-confs.sb")'
  '(import-profile "3-caches.sb")'
)

if ((AUTH)); then
  # shellcheck disable=SC2154
  ARGV+=(-D SSH_AUTH_SOCK="$SSH_AUTH_SOCK")
  PROFILES+=('(import-profile "1-auth.sb")')
fi

if ((NETWORK)); then
  PROFILES+=('(import-profile "1-network.sb")')
fi

for I in "${!DIRS[@]}"; do
  read -r -d '' -- RULE <<- SCHEME || true
(allow file-read* file-write*
  (subpath (param "D${I}")))
SCHEME

  PROFILES+=("$RULE")
  ARGV+=(-D "D${I}=${DIRS[$I]}")
done

for I in "${!FILES[@]}"; do
  read -r -d '' -- RULE <<- SCHEME || true
(allow file-read* file-write*
  (literal (param "F${I}")))
SCHEME

  PROFILES+=("$RULE")
  ARGV+=(-D "F${I}=${FILES[$I]}")
done

PROFILES+=("${USER_PROFILES[@]}")

IFS=$'\n'
PROFILE="${PROFILES[*]}"
unset -- IFS
ARGV+=(-p "$PROFILE")

exec -- "${ARGV[@]}" -- "$@"
