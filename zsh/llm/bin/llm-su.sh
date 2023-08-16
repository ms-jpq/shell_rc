#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

OPTS='m:,p:,t:'
LONG_OPTS='model:,prompt:,tee:'
GO="$(getopt --options="$OPTS" --longoptions="$LONG_OPTS" --name="$0" -- "$@")"
eval -- set -- "$GO"

ARGV=("$@")

GPT_HISTORY="${GPT_HISTORY:-"$(mktemp)"}"
GPT_TMP="${GPT_TMP:-"$(mktemp)"}"
GPT_LVL="${GPT_LVL:-1}"
export -- GPT_HISTORY GPT_TMP GPT_LVL

MODEL='gpt-3.5-turbo'
PROMPTS=()
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
  -p | --prompt)
    PROMPTS+=("$2")
    shift -- 2
    ;;
  -t | --tee)
    TEE="$2"
    mkdir -v -p -- "$TEE" >&2
    shift -- 2
    ;;
  *)
    exit 1
    ;;
  esac
done

SYS=("$*")
for PROMPT in "${PROMPTS[@]}"; do
  SYS+=("$(<"$PROMPT")")
done
SYSTEM="${SYS[*]}"

# shellcheck disable=SC2016
JQ1=(
  jq
  --exit-status
  --raw-input
  --slurp
  '{ role: $role, content: . }'
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
EXEC=("${0%/*}/../libexec/llm-completion.sh" "$GPT_TMP")
TEEF=(tee --)
if [[ -v TEE ]]; then
  TEEF+=("$TEE/$GPT_LVL.tx.txt")

  if ((GPT_LVL == 1)); then
    printf '%s' "$SYSTEM" >"$TEE/_.txt"
  fi
fi

if ! [[ -s "$GPT_HISTORY" ]]; then
  "${JQ1[@]}" system <<<"${SYS[@]}" >"$GPT_HISTORY"
fi

if [[ -t 0 ]]; then
  read -r -d '' -- INPUT
  "${TEEF[@]}" <<<"$INPUT" | "${JQ1[@]}" user
else
  "${TEEF[@]}" | "${JQ1[@]}" user
fi >>"$GPT_HISTORY"

if [[ -t 1 ]]; then
  printf -v JQHIST -- '%q ' jq '.' "$GPT_HISTORY"
  printf -- '\n%s\n' "$JQHIST"
fi >&2

QUERY="$("${JQ2[@]}")"
if [[ -v TEE ]]; then
  "${EXEC[@]}" <<<"$QUERY" | tee -- "$TEE/$GPT_LVL.rx.md"
else
  "${EXEC[@]}" <<<"$QUERY"
fi

if [[ -t 0 ]]; then
  ((GPT_LVL++))
  exec -- "$0" "${ARGV[@]}"
fi
