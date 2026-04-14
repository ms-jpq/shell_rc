#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

OPTS=''
LONG_OPTS=''
GO="$(getopt --options="$OPTS" --longoptions="$LONG_OPTS" --name="$0" -- "$@")"
eval -- set -- "$GO"

export -- BASE=''
FILTER=(tee)
while (($#)); do
  case "$1" in
  --staged)
    BASE='HEAD'
    FILTER=(sed -z -E -e '/^[ ?]/d')
    break
    ;;
  --unstaged)
    FILTER=(sed -z -E -e '/^.[ ?]/d')
    break
    ;;
  --)
    shift -- 1
    break
    ;;
  *)
    if git rev-parse --verify --quiet "$1" > /dev/null; then
      BASE="$1"
      break
    fi
    ;;
  esac
done

if ! [[ -v RECUR ]]; then
  git status --porcelain --no-renames -z -- "${*:-.}" | "${FILTER[@]}" | sed -E -z -e 's#^...##' | RECUR=1 "$0"
  exit
fi

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
