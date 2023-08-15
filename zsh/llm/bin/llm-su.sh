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

JQ1=(
  jq
  --exit-status
  --raw-input
  '{ role: "user", content: . }'
  --slurp
)
# shellcheck disable=SC2016
JQ2=(
  jq
  --exit-status
  --slurp
  --arg model "$MODEL"
  --arg sys "$SYS"
  '{ model: $model, messages: ([{ role: "system", content: $sys }] + .) }'
  "$GPT_HISTORY"
)
CURL=(
  "${0%%-*}"
  --write-out '%{http_code}'
  --output "$GPT_TMP"
  --data @-
  -- 'https://api.openai.com/v1/chat/completions'
)

if [[ -t 1 ]]; then
  PAGER='glow'
else
  PAGER='cat'
fi

read -r -d '' -- INPUT || true
"${JQ1[@]}" <<<"$INPUT" >>"$GPT_HISTORY"

if [[ -t 0 ]]; then
  # shellcheck disable=SC2154
  "$XDG_CONFIG_HOME/zsh/libexec/hr.sh" '?'
fi

QUERY="$("${JQ2[@]}")"
CODE="$(RECURSION=1 "${CURL[@]}" <<<"$QUERY")"
if ((CODE != 200)); then
  jq <"$GPT_TMP" || cat -- "$GPT_TMP"
else
  jq --exit-status --raw-output '.choices[].message.content' <"$GPT_TMP" | "$PAGER"
fi

if [[ -t 0 ]]; then
  exec -- "$0" "${ARGV[@]}"
fi
