#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail
shopt -u failglob

SOUND=''
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

SOCK=(/tmp/kitty.*.sock)

if [[ ! -t 1 && -t 2 ]]; then
  exec >&2
fi
if [[ -t 1 ]]; then
  exec -- "$BASE/osc99.sh" "${ARGS[@]}"
fi

case "$OSTYPE" in
darwin*)
  if pgrep -x -- Hammerspoon > /dev/null 2>&1; then
    exec -- "$BASE/hs.lua" "${ARGS[@]}"
  elif ((${#SOCK[@]})); then
    exec -- "$BASE/kitten.sh" "${ARGS[@]}"
  else
    exec -- "$BASE/osascript.cjs" "${ARGS[@]}"
  fi
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
