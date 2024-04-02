#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

export -- MSYSTEM='MSYS' MSYS='winsymlinks:nativestrict'

PATH="/usr/bin:$PATH"

USERPROFILE="${USERPROFILE:-"$HOME"}"
APPDATA="${APPDATA:-"$USERPROFILE/AppData/Roaming"}"
LOCALAPPDATA="${LOCALAPPDATA:-"$USERPROFILE/AppData/Local"}"
TEMP="$LOCALAPPDATA/Temp"
LOCALLO="$USERPROFILE/AppData/LocalLow"
LOCALHI="$USERPROFILE/AppData/LocalHigh"

PWSH="$USERPROFILE/Documents/PowerShell"
PS1="$USERPROFILE/.config/powershell/Microsoft.PowerShell_profile.ps1"

mkdir -v -p -- "$USERPROFILE/.local" "$LOCALHI" "$PWSH"

declare -A -- LINKS=()
LINKS=(
  ["$USERPROFILE/.cache"]="$TEMP"
  ["$USERPROFILE/.config"]="$LOCALAPPDATA"
  ["$USERPROFILE/.local/opt"]="$LOCALHI"
  ["$USERPROFILE/.local/share"]="$APPDATA"
  ["$USERPROFILE/.local/state"]="$LOCALLO"
)

if [[ -f "$PS1" ]]; then
  LINKS["$PWSH/Microsoft.PowerShell_profile.ps1"]="$PS1"
fi

for FROM in "${!LINKS[@]}"; do
  TO="${LINKS["$FROM"]}"
  if ! [[ -e "$FROM" ]]; then
    FROM="$(/usr/bin/cygpath --absolute --windows "$FROM")"
    TO="$(/usr/bin/cygpath --absolute --windows "$TO")"
    PARENT="$(dirname -- "$FROM")"
    if [[ -d "$TO" ]]; then
      printf -v LINK -- 'mklink /j "%s" "%s"' "$TO" "$FROM"
    else
      printf -v LINK -- 'mklink "%s" "%s"' "$TO" "$FROM"
    fi
    printf -- '%s\n' "$LINK"
    mkdir -v -p -- "$PARENT"
    # cmd "$LINK"
  fi
done
