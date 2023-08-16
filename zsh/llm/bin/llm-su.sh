#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

OPTS='m:'
LONG_OPTS='model:'
GO="$(getopt --options="$OPTS" --longoptions="$LONG_OPTS" --name="$0" -- "$@")"
eval -- set -- "$GO"

ARGV=("$@")

GPT_HISTORY="${GPT_HISTORY:-"$(mktemp)"}"
GPT_TMP="${GPT_TMP:-"$(mktemp)"}"
export -- GPT_HISTORY GPT_TMP

MODEL='gpt-3.5-turbo'
while (($#)); do
  case "$1" in
  --)
    shift -- 1
    break
    ;;
  -m | --model)
    MODEL="$2"
    shift -- 2
    ;;
  *)
    exit 1
    ;;
  esac
done

SYS="$*"

# shellcheck disable=SC2016
JQ1=(
  jq
  --exit-status
  --raw-input
  '{ role: $role, content: . }'
  --slurp
  --arg role
)
# shellcheck disable=SC2016
JQ2=(
  jq
  --exit-status
  --slurp
  --arg model "$MODEL"
  '{ model: $model, messages: . }'
  "$GPT_HISTORY"
)

if ! [[ -s "$GPT_HISTORY" ]]; then
  "${JQ1[@]}" system <<<"$SYS" >"$GPT_HISTORY"
fi

if [[ -t 0 ]]; then
  read -r -d '' -- INPUT
  "${JQ1[@]}" user <<<"$INPUT"
else
  "${JQ1[@]}" user
fi >>"$GPT_HISTORY"

if [[ -t 1 ]]; then
  printf -v JQHIST -- '%q ' jq '.' "$GPT_HISTORY"
  printf -- '\n%s\n' "$JQHIST"
fi

QUERY="$("${JQ2[@]}")"
"${0%%-*}-completion" "$GPT_TMP" <<<"$QUERY"

if [[ -t 0 ]]; then
  exec -- "$0" "${ARGV[@]}"
fi
