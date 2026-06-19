#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail
shopt -u failglob

ID=''
ICON=''
SOUND=''
while (($#)); do
  case "$1" in
  -i | --id)
    ID="$2"
    shift -- 2
    ;;
  --id=*)
    ID="${1#*=}"
    shift -- 1
    ;;
  -I | --icon)
    ICON="$2"
    shift -- 2
    ;;
  --icon=*)
    ICON="${1#*=}"
    shift -- 1
    ;;
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

SOCK=(/tmp/kitty.*.sock)
if ((${#SOCK[@]})); then
  ARGV=("$BASE/kitty.sh" "$TITLE" "$BODY")
  if [[ -n $ID ]]; then
    ARGV+=(--identifier "$ID")
  fi
  if [[ -n $ICON ]]; then
    ARGV+=(--icon "$ICON")
  fi
  exec -- "${ARGV[@]}"
fi

case "$OSTYPE" in
darwin*)
  ARGV=("$BASE/osascript.cjs" "$TITLE" '' "$BODY")
  if [[ -n $SOUND ]]; then
    ARGV+=("$SOUND")
  fi
  exec -- "${ARGV[@]}"
  ;;
*)
  set -x
  exit 2
  ;;
esac
