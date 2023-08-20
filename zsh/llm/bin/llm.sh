#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

if ! (($#)); then
  printf -- 'llm %s\n' request token
  for F in "$0"*; do
    F="${F##*/}"
    F="${F/-/ }"
    if [[ "$F" != 'llm' ]]; then
      printf -- '%s\n' "$F"
    fi
  done
  exit
fi

NETRC="$HOME/.netrc"
edit() {
  mkdir -v -p -- "${NETRC%/*}"
  touch -- "$NETRC"
  chmod 0600 "$NETRC"
  # shellcheck disable=SC2154
  exec -- $EDITOR "$NETRC"
}

if ! [[ -s "$NETRC" ]]; then
  tee -- "$NETRC" <<-EOF
machine api.openai.com
password
EOF
  edit
fi

if ! [[ -v RECURSION ]]; then
  PROGRAM="${1:-""}"
  case "$PROGRAM" in
  r | request)
    shift -- 1
    ;;
  t | token)
    edit
    ;;
  *)
    shift -- 1
    exec -- "$0-$PROGRAM" "$@"
    ;;
  esac
fi

CURL=(
  curl
  --header 'Content-Type: application/json'
  --no-progress-meter
  "$@"
)

if [[ -t 1 ]]; then
  "${CURL[@]}" | jq --exit-status --sort-keys
else
  exec -- "${CURL[@]}"
fi
