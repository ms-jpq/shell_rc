#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

OPTS='x:,a:,b:,c:,h:,v:,r'
LONG_OPTS='method:,auth:,bearer:,cookie:,header:,var:,raw'
GO="$(getopt --options="$OPTS" --longoptions="$LONG_OPTS" --name="$0" -- "$@")"
eval -- set -- "$GO"

AV=("$@")

CURL=()
RAW=0
VAR='{}'
while (($#)); do
  case "$1" in
  -x | --method)
    CURL+=(--request "$2")
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
  -b | --bearer)
    CURL+=(--oauth2-bearer "$2")
    shift -- 2
    ;;
  -v | --var)
    KEY="${2%%=*}"
    VAL="${2#*=}"
    VAR="$(jq --exit-status --arg key "$KEY" --arg val "$VAL" '.[$key] = $val' <<<"$VAR")"
    shift -- 2
    ;;
  -r | --raw)
    RAW=1
    shift -- 1
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
  --header 'Content-Type: application/json'
  --data-binary @-
  "${CURL[@]}"
)

read -r -d '' -- QUERY
JSON="$(jq --exit-status --slurp --raw-input --argjson var "$VAR" '{ query: ., variables: $var }' <<<"$QUERY")"

{
  printf -- '\n'
  printf -- '%q ' "${ARGV[@]}"
  printf -- '\n'
  jq --sort-keys <<<"$VAR"
} >&2

if ((RAW)); then
  TEE=(tee --)
else
  TEE=(jq --sort-keys)
fi

if "${ARGV[@]}" <<<"$JSON" | "${TEE[@]}"; then
  :
fi
if [[ -t 1 ]]; then
  exec -- "$0" "${AV[@]}"
fi
