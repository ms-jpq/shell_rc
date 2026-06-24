#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail
shopt -u failglob

SOUND=''
ID=''
while (($#)); do
  case "$1" in
  -s | --sound)
    SOUND="$2"
    shift -- 2
    ;;
  --sound=*)
    SOUND="${1#*=}"
    shift -- 1
    ;;
  -i | --id)
    ID="$2"
    shift -- 2
    ;;
  --id=*)
    ID="${1#*=}"
    shift -- 1
    ;;
  --)
    shift -- 1
    break
    ;;
  -*)
    set -x
    exit 2
    ;;
  *)
    break
    ;;
  esac
done

TITLE="$1"
BODY="${2-}"

ROOT="$(realpath -- "$0")"
BASE="${ROOT%/*}"

ARGS=("$TITLE" "$BODY")
if [[ -n $SOUND ]]; then
  ARGS+=("$SOUND")
fi

SOCK=({"${TMPDIR:-/tmp}",/tmp}/kitty.*.sock)

case "$OSTYPE" in
darwin*)
  if hs -c 'return ""' 2> /dev/null; then
    HS_ARGS=("$TITLE" "$BODY" "$SOUND" "$ID")
    exec -- "$BASE/hammerspoon.lua" "${HS_ARGS[@]}"
  fi
  if ((${#SOCK[@]})); then
    exec -- "$BASE/kitten.sh" "${ARGS[@]}"
  fi
  for FD in 1 2; do
    if [[ -t $FD ]]; then
      exec -- "$BASE/osc99.sh" "${ARGS[@]}" >&"$FD"
    fi
  done
  exec -- "$BASE/osascript.cjs" "${ARGS[@]}"
  ;;
linux*)
  if ((${#SOCK[@]})); then
    exec -- "$BASE/kitten.sh" "${ARGS[@]}"
  fi
  set -x
  exit 2
  ;;
*)
  set -x
  exit 2
  ;;
esac
