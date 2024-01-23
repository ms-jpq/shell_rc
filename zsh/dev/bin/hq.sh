#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

OPTS='x:,m:,a:,b:,c:,h:,p:'
LONG_OPTS='method:,mime:,auth:,bearer:,cookie:,header:,pager:'
GO="$(getopt --options="$OPTS" --longoptions="$LONG_OPTS" --name="$0" -- "$@")"
eval -- set -- "$GO"

AV=("$@")

MIME='application/json'
CURL=()
PAGER=(cat)
while (($#)); do
  case "$1" in
  -x | --method)
    CURL+=(--request "$2")
    shift -- 2
    ;;
  -m | --mime)
    MIME="$2"
    shift -- 2
    ;;
  -b | --bearer)
    CURL+=(--oauth2-bearer "$2")
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
  -p | --pager)
    # shellcheck disable=SC2206
    PAGER=($2)
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
  --no-progress-meter
  --header "Content-Type: $MIME"
  --data @-
  "${CURL[@]}"
)

read -r -d '' -- BODY

printf -- '\n'
printf -- '%q ' "${ARGV[@]}"
printf -- '\n'

printf -- '%s' "${BODY[@]}" | "${ARGV[@]}" | "${PAGER[@]}"
printf -- '\n'
exec -- "$0" "${AV[@]}"
