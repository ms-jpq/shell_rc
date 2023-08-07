#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

OPTS='m:,a:,c:,h:,v:'
LONG_OPTS='method:,auth:,cookie:,header:,var:'
GO="$(getopt --options="$OPTS" --longoptions="$LONG_OPTS" --name="$0" -- "$@")"
eval -- set -- "$GO"

AV=("$@")

METHOD=POST
CURL=()
VAR='{}'
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
  -v | --var)
    KEY="${2%%=*}"
    VAL="${2#*=}"
    VAR="$(jq --exit-status --arg key "$KEY" --arg val "$VAL" '.[$key] = $val' <<<"$VAR")"
    shift -- 2
    ;;
  --)
    shift -- 1
    CURL+=("$@")
    break
    ;;
  *)
    printf -- '%s\n' "$@"
    exit 1
    ;;
  esac
done

ARGV=(
  curl
  --location
  --no-progress-meter
  --request "$METHOD"
  --header 'Content-Type: application/json'
  --data @-
  "${CURL[@]}"
)

read -r -d '' -- QUERY
JSON="$(jq --exit-status --slurp --raw-input --argjson var "$VAR" '{ query: ., variables: $var }' <<<"$QUERY")"

printf -- '%q ' "${ARGV[@]}"
printf -- '\n'
jq <<<"$JSON"

"${ARGV[@]}" <<<"$JSON" | jq

"$0" "${AV[@]}"
