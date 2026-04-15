#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

OPTS='s'
LONG_OPTS='staged'
GO="$(getopt --options="$OPTS" --longoptions="$LONG_OPTS" --name="$0" -- "$@")"
eval -- set -- "$GO"

if ! [[ -v RECUR ]]; then
  SED='/^.[^ ]/p'
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

shift -- 1
BASE="$1"
readarray -t -d '' -- DIFFS

SPLIT=(new-window -a)
for FILE in "${DIFFS[@]}"; do
  BASENAME="$(basename -- "$FILE")"
  SUFFIX=''
  if [[ $BASENAME == *.* ]]; then
    SUFFIX=".${BASENAME##*.}"
  fi

  LHS="$(mktemp --suffix "$SUFFIX")"
  git show "$BASE:$FILE" > "$LHS" 2> /dev/null || :

  if [[ $BASE == 'HEAD' ]] && ! git diff --quiet -- "$FILE"; then
    RHS="$(mktemp --suffix "$SUFFIX")"
    git show ":$FILE" > "$RHS" 2> /dev/null || :
  else
    RHS="$(git --no-optional-locks rev-parse --path-format=absolute --show-toplevel)/$FILE"
  fi

  tmux "${SPLIT[@]}" -c "$PWD" -- nvim -d -- "$LHS" "$RHS"
  SPLIT=(split-window)
done

if ((${#DIFFS[@]})); then
  exec -- tmux select-layout tiled
fi
