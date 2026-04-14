#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

OPTS='s'
LONG_OPTS='staged'
GO="$(getopt --options="$OPTS" --longoptions="$LONG_OPTS" --name="$0" -- "$@")"
eval -- set -- "$GO"

if ! [[ -v RECUR ]]; then
  SED='/^[? ]/p'
  BASE=''
  while (($#)); do
    case "$1" in
    -s | --staged)
      BASE='HEAD'
      SED='/^[^? ]/p'
      break
      ;;
    --)
      shift -- 1
      break
      ;;
    *)
      BASE="$*"
      break
      ;;
    esac
  done
  git status --porcelain --no-renames -z -- . | sed -E -z --quiet -e "$SED" | sed -E -z -e 's#^...##' | RECUR=1 "$0" "$BASE"
  exit
fi

BASE="$1"
readarray -t -d '' -- DIFFS

SPLIT=(new-window -a)
for NEW in "${DIFFS[@]}"; do
  BASENAME="$(basename -- "$NEW")"

  SUFFIX=''
  if [[ $BASENAME == *.* ]]; then
    SUFFIX="${BASENAME##*.}"
  fi
  OLD="$(mktemp --suffix "$SUFFIX")"

  git show "$BASE:$NEW" > "$OLD" 2> /dev/null || :
  tmux "${SPLIT[@]}" -c "$PWD" -- nvim -d -- "$OLD" "$NEW"
  SPLIT=(split-window)
done
