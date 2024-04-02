#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

SRC="$2"
DST="$3"
REMOTE="${DST%%:*}"
SINK="${DST#*:}"
TMP="$SINK.tar"
DIR="$(dirname -- "$0")"

PWSH=(
  powershell.exe
  -NoProfile
  -NonInteractive
)

# shellcheck disable=SC1003
if [[ "$REMOTE" == 'localhost' ]]; then
  {
    tee -- <<-PWSH
\$src = "$SRC"
\$dst = "$SINK"
PWSH
    cat -- "$DIR/rsync.ps1"
  } | "${PWSH[@]}"
else
  # shellcheck disable=SC2206
  RSH=($1 "$REMOTE")
  TMP="\"$TMP\""

  "${RSH[@]}" "IF EXIST" "$TMP" "RMDIR" "/S" "/Q" "$TMP"
  "${RSH[@]}" "MKDIR" "$TMP"
  tar -c -C "$SRC" -- . | "${RSH[@]}" tar -x -p -C "$TMP"

  {
    tee -- <<-PWSH
\$src = $TMP
\$dst = "$SINK"
PWSH
    cat -- "$DIR/rsync.ps1"
  } | "${RSH[@]}" "${PWSH[@]}"
fi
