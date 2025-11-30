#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

OPTS='u:,p:,h:'
LONG_OPTS='lodpi,user:,pass:,host:'
GO="$(getopt --options="$OPTS" --longoptions="$LONG_OPTS" --name="$0" -- "$@")"
eval -- set -- "$GO"

HIDPI=1
UNAME='administrator'
PASS=''
HOST=
while true; do
  case "$1" in
  --lodpi)
    HIDPI=0
    shift -- 1
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

ARGV=(
  sdl-freerdp
  /cert:ignore
  /smart-sizing
  /f
  "/u:$UNAME"
  "/p:$PASS"
  "/v:$HOST"
)

SIZE='2880x1864'
if ((HIDPI)); then
  ARGV+=(/scale-desktop:200)
fi
ARGV+=("/size:$SIZE")

exec -- "${ARGV[@]}" "$@"
