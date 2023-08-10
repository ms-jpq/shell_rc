#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

OPTS='x:,m:,a:,c:,h:,t:'
LONG_OPTS='method:,mime:,auth:,cookie:,header:,tee:'
GO="$(getopt --options="$OPTS" --longoptions="$LONG_OPTS" --name="$0" -- "$@")"
eval -- set -- "$GO"

AV=("$@")

METHOD=POST
MIME='application/json'
CURL=()
TEE=(cat)
while (($#)); do
  case "$1" in
  -x | --method)
    METHOD="$2"
    shift -- 2
    ;;
  -m | --mime)
    MIME="$2"
    shift -- 2
    ;;
  -c | --cookie)
    CURL+=(--cookie "$2")
    shift -- 2
    ;;
  -h | --header)
    CURL+=(--header "$2")
    shift -- 2
    ;;
  -a | --auth)
    CURL+=(--header "Authorization: $2")
    shift -- 2
    ;;
  -t | --tee)
    # shellcheck disable=SC2206
    TEE=($2)
    shift -- 2
    ;;
  --)
    shift -- 1
    CURL+=("$@")
    break
    ;;
  *)
    exit 1
    ;;
  esac
done

ARGV=(
  curl
  --location
  --no-progress-meter
  --request "$METHOD"
  --header "Content-Type: $MIME"
  --data @-
  "${CURL[@]}"
)

read -r -d '' -- BODY

printf -- '\n'
printf -- '%q ' "${ARGV[@]}"
printf -- '\n'

printf -- '%s' "${BODY[@]}" | "${ARGV[@]}" | "${TEE[@]}"
printf -- '\n'
exec -- "$0" "${AV[@]}"
