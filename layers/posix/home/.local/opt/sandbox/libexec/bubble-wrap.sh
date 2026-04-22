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
    # shellcheck disable=SC2034
    AUTH=1
    shift -- 1
    ;;
  --network)
    # shellcheck disable=SC2034
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

exec -- "$@"
