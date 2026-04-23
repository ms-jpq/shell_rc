#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

OPTS='a,n,d:,f:'
LONG_OPTS='auth,network,dir:,file:'
GO="$(getopt --options="$OPTS" --longoptions="$LONG_OPTS" --name="$0" -- "$@")"
eval -- set -- "$GO"

AUTH=0
NETWORK=0
DIRS=()
FILES=()
while true; do
  case "$1" in
  -a | --auth)
    AUTH=1
    shift -- 1
    ;;
  -n | --network)
    NETWORK=1
    shift -- 1
    ;;
  -d | --dir)
    DIRS+=("$2")
    shift -- 2
    ;;
  -f | --file)
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

TMPDIR="$(realpath -- "$TMPDIR")"

ARGV=(
  sandbox-exec
  -D PROFILES="$ROOT/darwin"
  -D TMPDIR="$TMPDIR"
  -D HOME="$HOME"
)

PROFILES=(
  '(import (string-append (param "PROFILES") "/0-cli.sb"))'
  '(import-profile "0-system.sb")'
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

DIRS+=("$(realpath -- "$PWD:rw")")

for I in "${!DIRS[@]}"; do
  DIR="${DIRS[$I]}"
  if [[ $DIR == *:rw ]]; then
    DIR="${DIR%:rw}"

    read -r -d '' -- RULE <<- SCHEME || true
(allow file-read* file-write* (subpath (param "D${I}")))
SCHEME
  else
    read -r -d '' -- RULE <<- SCHEME || true
(allow file-read* (subpath (param "D${I}")))
SCHEME
  fi

  PROFILES+=("$RULE")
  ARGV+=(-D "D${I}=$DIR")
done

for I in "${!FILES[@]}"; do
  FILE="${FILES[$I]}"
  if [[ $FILE == *:rw ]]; then
    FILE="${FILE%:rw}"

    read -r -d '' -- RULE <<- SCHEME || true
(allow file-read* file-write* (literal (param "F${I}")))
SCHEME
  else
    read -r -d '' -- RULE <<- SCHEME || true
(allow file-read* (literal (param "F${I}")))
SCHEME
  fi

  PROFILES+=("$RULE")
  ARGV+=(-D "F${I}=$FILE")
done

PROFILES+=('(import-profile "6-deny.sb")')

IFS=$'\n'
PROFILE="${PROFILES[*]}"
unset -- IFS
ARGV+=(-p "$PROFILE")

exec -- "${ARGV[@]}" -- "$@"
