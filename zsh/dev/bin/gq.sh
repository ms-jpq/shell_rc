#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

OPTS='m:,a:,c:,h:'
LONG_OPTS='method:,auth:,cookie:,header:'
GO="$(getopt --options="$OPTS" --longoptions="$LONG_OPTS" --name="$0" -- "$@")"
eval -- set -- "$GO"

AV=("$@")

METHOD=POST
CURL=()
while (($#)); do
  case "$1" in
  -m | --method)
    METHOD="$2"
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
  --fail
  --location
  --no-progress-meter
  --request "$METHOD"
  --header 'Content-Type: application/json'
  --data @-
  "${CURL[@]}"
)

read -r -d '' -- QUERY

read -r -d '' -- JSON <<-EOF || true
{
  "query": "$QUERY"
}
EOF

printf -- '%q ' "${CURL[@]}"
printf -- '\n'

"${ARGV[@]}" <<<"$JSON" | jq

"$0" "${AV[@]}"
