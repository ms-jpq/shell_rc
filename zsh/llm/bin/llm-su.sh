#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

OPTS='m:,p:,t:'
LONG_OPTS='model:,prompt:,tee:'
GO="$(getopt --options="$OPTS" --longoptions="$LONG_OPTS" --name="$0" -- "$@")"
eval -- set -- "$GO"

ARGV=("$@")

GPT_HISTORY="${GPT_HISTORY:-"$(mktemp)"}"
GPT_TMP="${GPT_TMP:-"$(mktemp)"}"
GPT_LVL="${GPT_LVL:-0}"
export -- GPT_HISTORY GPT_TMP GPT_LVL

LIBEXEC="${0%/*}/../libexec"
MODEL="$(<"$LIBEXEC/model")"

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
EXEC=("$LIBEXEC/llm-completion.sh" "$GPT_TMP")
TEEF=(tee --)
if [[ -v TEE ]]; then
  EXEC+=("$TEE/$GPT_LVL.rx.md")
  TEEF+=("$TEE/$GPT_LVL.tx.txt")

  if ! ((GPT_LVL)); then
    printf -- '%s\n' "${SYS[@]}" >"$TEE/_.txt"
  fi
fi

if ! [[ -s "$GPT_HISTORY" ]]; then
  for S in "${SYS[@]}"; do
    "${JQ1[@]}" system <<<"$S" >>"$GPT_HISTORY"
  done
fi

if [[ -t 0 ]]; then
  INPUT="$("$LIBEXEC/llm-wrap.sh" "$0")"
  "${TEEF[@]}" <<<"$INPUT" | "${JQ1[@]}" user
else
  "${TEEF[@]}" | "${JQ1[@]}" user
fi >>"$GPT_HISTORY"

if [[ -t 1 ]]; then
  printf -v JQHIST -- '%q ' jq '.' "$GPT_HISTORY"
  printf -- '\n%s\n' "$JQHIST"
fi >&2

QUERY="$("${JQ2[@]}")"
"$LIBEXEC/hr.sh" >&2
"${EXEC[@]}" <<<"$QUERY"

if [[ -t 0 ]]; then
  ((++GPT_LVL))
  exec -- "$0" "${ARGV[@]}"
fi
