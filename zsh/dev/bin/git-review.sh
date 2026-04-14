#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

if ! [[ -v RECUR ]]; then
  export -- BASE=''

  for ARG in "$@"; do
    case "$*" in
    --cached | --staged)
      BASE='HEAD'
      break
      ;;
    *)
      if git rev-parse --verify --quiet "$ARG" > /dev/null; then
        BASE="$ARG"
        break
      fi
      ;;
    esac

  done

  git status --porcelain --no-renames -z -- . | sed -E -z -e 's#^...##' | RECUR=1 "$0"
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

  git show "$BASE:$NEW" > "$OLD"
  tmux "${SPLIT[@]}" -c "$PWD" -- nvim -d -- "$OLD" "$NEW"
  SPLIT=(split-window)
done
