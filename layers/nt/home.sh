#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

export -- MSYSTEM='MSYS' MSYS='winsymlinks:nativestrict'

PATH="/usr/bin:$PATH"

USERPROFILE="${USERPROFILE:-"$HOME"}"
APPDATA="${APPDATA:-"$USERPROFILE/AppData/Roaming"}"
LOCALAPPDATA="${LOCALAPPDATA:-"$USERPROFILE/AppData/Local"}"
WINTMP="$LOCALAPPDATA/Temp"
LOCALLO="$USERPROFILE/AppData/LocalLow"
LOCALHI="$USERPROFILE/AppData/LocalHigh"

CONF="$USERPROFILE/.config"
PWSH="$USERPROFILE/Documents/PowerShell"
PS1="$CONF/powershell/Microsoft.PowerShell_profile.ps1"

mkdir -v -p -- "$USERPROFILE/.local" "$LOCALHI" "$PWSH"

declare -A -- LINKS=()
LINKS=(
  ["$CONF"]="$LOCALAPPDATA"
  ["$USERPROFILE/.cache"]="$WINTMP"
  ["$USERPROFILE/.local/opt"]="$LOCALHI"
  ["$USERPROFILE/.local/share"]="$APPDATA"
  ["$USERPROFILE/.local/state"]="$LOCALLO"
)

for FROM in "${!LINKS[@]}"; do
  TO="${LINKS["$FROM"]}"
  if ! [[ -L "$FROM" ]]; then
    PARENT="$(dirname -- "$FROM")"
    mkdir -v -p -- "$PARENT"
    FROM="$(cygpath --windows -- "$FROM")"
    TO="$(cygpath --windows -- "$TO")"
    powershell.exe New-Item -ItemType Junction -Path "$FROM" -Target "$TO"
  fi
done

if [[ -f "$PS1" ]]; then
  LINKS["$PWSH/Microsoft.PowerShell_profile.ps1"]="$PS1"
fi
