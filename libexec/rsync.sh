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
  -EncodedCommand
)

# shellcheck disable=SC1003
if [[ "$REMOTE" == 'localhost' ]]; then
  CMD="$(
    {
      tee -- <<-PWSH
\$src = "$SRC"
\$dst = "$SINK"
PWSH
      cat -- "$DIR/rsync.ps1"
    } | recode utf8..utf16le | base64 | tr -d -- '\n'
  )"
  "${PWSH[@]}" "$CMD"
else
  # shellcheck disable=SC2206
  RSH=($1 "$REMOTE")
  TMP="\"$TMP\""

  "${RSH[@]}" "IF EXIST" "$TMP" "RMDIR" "/S" "/Q" "$TMP"
  "${RSH[@]}" "MKDIR" "$TMP"
  tar -c -C "$SRC" -- . | "${RSH[@]}" tar -x -p -C "$TMP"

  CMD="$(
    {
      tee -- <<-PWSH
\$src = $TMP
\$dst = "$SINK"
PWSH
      cat -- "$DIR/rsync.ps1"
    } | recode utf8..utf16le | base64 | tr -d -- '\n'
  )"
  "${RSH[@]}" "${PWSH[@]}" "$CMD"
fi
