#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

OPTS='m:,t:,r:'
LONG_OPTS='model:,temperature:,role:'
GO="$(getopt --options="$OPTS" --longoptions="$LONG_OPTS" --name="$0" -- "$@")"
eval -- set -- "$GO"

ARGV=("$@")

GPTHIST="${GPTHIST:-"$(mktemp)"}"
GPTTMP="${GPTTMP:-"$(mktemp)"}"

export -- GPTHIST GPTTMP

MODEL='gpt-3.5-turbo'
ROLE='system'

while (($#)); do
  case "$1" in
  -m | --model)
    MODEL="$2"
    shift -- 2
    ;;
  -t | --temperature)
    TEMP="$2"
    shift -- 2
    ;;
  -r | --role)
    ROLE="$2"
    shift -- 2
    ;;
  --)
    shift -- 1
    break
    ;;
  *)
    exit 1
    ;;
  esac
done

read -r -d '' -- MSG
jq --exit-status --raw-input --arg role "$ROLE" '{ role: $role, content: . }' <<<"$MSG" >>"$GPTHIST"

# shellcheck disable=SC2016
JQ=(
  jq
  --exit-status
  --slurp
  --arg model "$MODEL"
  --arg temp "${TEMP:-"$(jot -r -p 1 1 0 2)"}"
  '{ model: $model, temperature: ($temp | tonumber), messages: . }'
)
LLMQ=(
  "${0%%-*}"
  --write-out '%{http_code}'
  --output "$GPTTMP"
  --data @-
  -- 'https://api.openai.com/v1/chat/completions'
)

JSON="$("${JQ[@]}" <"$GPTHIST")"

# shellcheck disable=SC2154
"$XDG_CONFIG_HOME/zsh/libexec/hr.sh"
printf -v LINE -- '%q ' jq '.' "$GPTHIST"
printf -- '%s\n' "$LINE"

CODE="$(RECURSION=1 "${LLMQ[@]}" <<<"$JSON")"

if ((CODE != 200)); then
  jq <"$GPTTMP" || cat -- "$GPTTMP"
else
  jq --exit-status --raw-output '.choices[].message.content' <"$GPTTMP" | glow
fi

exec -- "$0" "${ARGV[@]}"
