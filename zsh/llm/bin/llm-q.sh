#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

OPTS='m:,r:,h:'
LONG_OPTS='model:,role:,history:'
GO="$(getopt --options="$OPTS" --longoptions="$LONG_OPTS" --name="$0" -- "$@")"
eval -- set -- "$GO"

ARGV=("$@")

GPT_HISTORY="${GPT_HISTORY:-"$(mktemp)"}"
GPT_TMP="${GPT_TMP:-"$(mktemp)"}"
export -- GPT_HISTORY GPT_TMP

MODEL='gpt-3.5-turbo'
ROLE='user'

while (($#)); do
  case "$1" in
  -m | --model)
    MODEL="$2"
    shift -- 2
    ;;
  -r | --role)
    ROLE="$2"
    shift -- 2
    ;;
  -h | --history)
    GPT_HISTORY="$2"
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

hr() {
  # shellcheck disable=SC2154
  "$XDG_CONFIG_HOME/zsh/libexec/hr.sh" "$@"
}

# shellcheck disable=SC2016
JQ1=(
  jq
  --exit-status
  --raw-input
  --arg role "$ROLE"
  '{ role: $role, content: . }'
)
# shellcheck disable=SC2016
JQ2=(
  jq
  --exit-status
  --slurp
  --arg model "$MODEL"
  '{ model: $model, messages: . }'
)
CURL=(
  "${0%%-*}"
  --write-out '%{http_code}'
  --output "$GPT_TMP"
  --data @-
  -- 'https://api.openai.com/v1/chat/completions'
)

read -r -d '' -- INPUT
printf -- '\n'
read -r -- LINE <<<"$INPUT"
PRAGMA="$(tr -d ' ' <<<"$LINE")"
P=1
REEXEC=0
case "$PRAGMA" in
'>die')
  GPT_HISTORY="$(mktemp)"
  REEXEC=1
  ;;
'>clear')
  GPT_HISTORY="$(mktemp)"
  ;;
'>role'*)
  ROLE="${PRAGMA#'>role'}"
  INPUT="$(sed '1d' <<<"$INPUT")"
  ;;
*) P=0 ;;
esac

if ((P)); then
  hr !
  printf -- '%s\n' "$LINE"
  hr !
  if ((REEXEC)); then
    exec -- "$0" "${ARGV[@]}"
  fi
fi

"${JQ1[@]}" <<<"$INPUT" >>"$GPT_HISTORY"
QUERY="$("${JQ2[@]}" <"$GPT_HISTORY")"

hr
printf -v JQHIST -- '%q ' jq '.' "$GPT_HISTORY"
printf -- '%s\n%s\n' "$JQHIST" "> $ROLE:"
hr '?'

CODE="$(RECURSION=1 "${CURL[@]}" <<<"$QUERY")"
if ((CODE != 200)); then
  jq <"$GPT_TMP" || cat -- "$GPT_TMP"
else
  jq --exit-status --raw-output '.choices[].message.content' <"$GPT_TMP" | glow
fi

exec -- "$0" "${ARGV[@]}"
