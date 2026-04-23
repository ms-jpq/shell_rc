#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

ROOT="$1"
shift -- 1

EXIT=1
STEP="$ROOT"
while [[ $STEP != "/" ]] && [[ $STEP != '' ]]; do
  for FILE in "$STEP/"*; do
    NAME="${FILE##*/}"

    for PAT in "$@"; do
      # shellcheck disable=SC2254
      case "$NAME" in
      $PAT)
        printf -- '%s\n' "${FILE%/*}"
        EXIT=0
        ;;
      *) ;;
      esac
    done
  done
  STEP="${STEP%/*}"
done

exit "$EXIT"
