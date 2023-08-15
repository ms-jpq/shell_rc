#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

if ! (($#)); then
  printf -- '%q\n' "$0"*
  exit
fi

# shellcheck disable=SC2154
TOKEN_F="$XDG_STATE_HOME/gpt/token"
edit() {
  mkdir -v -p -- "${TOKEN_F%/*}"
  # shellcheck disable=SC2154
  exec -- $EDITOR "$TOKEN_F"
}

if ! [[ -v RECURSION ]]; then
  PROGRAM="${1:-""}"
  case "$PROGRAM" in
  r | request)
    shift -- 1
    ;;
  e | edit)
    edit
    ;;
  *)
    shift -- 1
    exec -- "$0-$PROGRAM" "$@"
    ;;
  esac
fi

if ! [[ -f "$TOKEN_F" ]]; then
  edit
fi

TOKEN="$(<"$TOKEN_F")"

CURL=(
  curl
  --header 'Content-Type: application/json'
  --oauth2-bearer "$TOKEN"
  --no-progress-meter
  "$@"
)

if [[ -t 1 ]]; then
  "${CURL[@]}" | jq --exit-status --sort-keys
else
  exec -- "${CURL[@]}"
fi
