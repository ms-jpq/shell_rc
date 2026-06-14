#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

CHOOSER=''
while (($#)); do
  case "$1" in
  --chooser-file)
    CHOOSER="$2"
    shift -- 2
    ;;
  --)
    shift -- 1
    break
    ;;
  *)
    break
    ;;
  esac
done

TARGET="$1"

if command -v -- yazi > /dev/null; then
  YAZI=(yazi)
  if [[ -n $CHOOSER ]]; then
    YAZI+=(--chooser-file "$CHOOSER")
  fi
  YAZI+=(-- "$TARGET")
  exec -- "${YAZI[@]}"
fi

if [[ -d $TARGET ]]; then
  DIR="$TARGET"
else
  DIR="$(dirname -- "$TARGET")"
fi

RANGER=(ranger --selectfile "$TARGET")
if [[ -n $CHOOSER ]]; then
  RANGER+=(--choosefile "$CHOOSER")
fi
RANGER+=(-- "$DIR")
exec -- "${RANGER[@]}"
