#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

OPTS='s:,u:,p:,h:'
LONG_OPTS='size:,user:,pass:,host:'
GO="$(getopt --options="$OPTS" --longoptions="$LONG_OPTS" --name="$0" -- "$@")"
eval -- set -- "$GO"

ADMIN='administrator'

SIZE=''
UNAME="$ADMIN"
PASS=''
HOST=''
while true; do
  case "$1" in
  -s | --size)
    SIZE="$2"
    shift -- 2
    ;;
  -u | --user)
    UNAME="$2"
    shift -- 2
    ;;
  -p | --pass)
    PASS="$2"
    shift -- 2
    ;;
  -h | --host)
    HOST="$2"
    shift -- 2
    ;;
  --)
    shift -- 1
    break
    ;;
  *)
    exit 2
    ;;
  esac
done

if [[ -z $HOST ]]; then
  set -x
  exit 2
fi

if [[ -z $SIZE ]]; then
  set -x
  system_profiler SPDisplaysDataType | sed -E -n 's#^ +Resolution: ([0-9]+) x ([0-9]+).*$#\1x\2#p'
  exit 2
fi

ARGV=(
  sdl-freerdp
  /cert:ignore
  "/size:$SIZE"
  "/u:$UNAME"
  "/p:$PASS"
  "/v:$HOST"
  +dynamic-resolution
  -wallpaper
  -themes
  -decorations
)

if [[ $UNAME == "$ADMIN" ]]; then
  ARGV+=(/admin)
fi

exec -- "${ARGV[@]}" "$@"
