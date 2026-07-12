#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

AUTH=0
NETWORK=0
DIRS=()
FILES=()
while (($#)); do
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
  --dir=*)
    DIRS+=("${1#*=}")
    shift -- 1
    ;;
  -f | --file)
    FILES+=("$2")
    shift -- 2
    ;;
  --file=*)
    FILES+=("${1#*=}")
    shift -- 1
    ;;
  --)
    shift -- 1
    break
    ;;
  -*)
    set -x
    exit 2
    ;;
  *)
    break
    ;;
  esac
done

if ! touch -- "$HOME/Library" 2> /dev/null; then
  exec -- "$@"
fi

ROOT="$(realpath -- "${0%/*}/..")"

ARGV=(
  sandbox-exec
  -D PROFILES="$ROOT/darwin"
  -D HOME="$HOME"
)

PROFILES=(
  '(import (string-append (param "PROFILES") "/main.sb"))'
)

if ((AUTH)); then
  # shellcheck disable=SC2154
  ARGV+=(-D SSH_AUTH_SOCK="$SSH_AUTH_SOCK")
  PROFILES+=('(import-profile "1-auth.sb")')
fi

if ((NETWORK)); then
  PROFILES+=('(import-profile "1-network.sb")')
fi

DIRS+=("$(realpath -- "$TMPDIR"):rw")
DIRS+=("$(realpath -- "$PWD"):rw")

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
