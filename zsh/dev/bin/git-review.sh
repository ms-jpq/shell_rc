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

  read -r -d '' -- _AWK <<- 'AWK' || true
{ print }
AWK

  git status --porcelain --no-renames -z -- . | sed -E -z --quiet -e "$SED" | sed -E -z -e 's#^...##' | while IFS='' read -r -d '' -- F; do
    if [[ $F == */ ]]; then
      find -- "$F" -type f -print0
    else
      printf -- '%s\0' "$F"
    fi
  done | RECUR=1 "$0" "$BASE"
  exit
fi

shift -- 1
BASE="$1"
readarray -t -d '' -- DIFFS

for I in "${!DIFFS[@]}"; do
  FILE="${DIFFS[$I]}"

  if ((I % 4 == 0)); then
    SPLIT=(new-window -a)
  else
    SPLIT=(split-window)
  fi

  BASENAME="${FILE##*/}"
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

  if ((I % 4 == 3)) || ((I == ${#DIFFS[@]} - 1)); then
    tmux select-layout -- tiled
  fi
done
