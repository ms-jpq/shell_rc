#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

OPTS='s:,u:,p:,h:'
LONG_OPTS='video,user:,pass:,host:'
GO="$(getopt --options="$OPTS" --longoptions="$LONG_OPTS" --name="$0" -- "$@")"
eval -- set -- "$GO"

ADMIN='administrator'

UNAME="$ADMIN"
PASS=''
HOST=''
VIDEO=0
while true; do
  case "$1" in
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
  --video)
    VIDEO=1
    shift -- 1
    ;;
  --)
    shift -- 1
    break
    ;;
  *)
    set -v
    exit 2
    ;;
  esac
done

if [[ -z $HOST ]]; then
  set -v
  exit 2
fi

ARGV=(
  sdl-freerdp
  /cert:ignore
  "/u:$UNAME"
  "/p:$PASS"
  "/v:$HOST"
  +dynamic-resolution
  -wallpaper
  +async-update
  +auto-reconnect
)

if [[ $UNAME == "$ADMIN" ]]; then
  ARGV+=(/admin)
fi

if ((VIDEO)); then
  ARGV+=(/video /sound)
fi

exec -- "${ARGV[@]}" "$@"
