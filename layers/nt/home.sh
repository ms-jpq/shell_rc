#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

export -- MSYSTEM='MSYS' MSYS='winsymlinks:nativestrict'

PATH="/usr/bin:$PATH"

# shellcheck disable=2154
WINTMP="$LOCALAPPDATA/Temp"
# shellcheck disable=2154
LOCALLO="${LOCALAPPDATA}Low"
LOCALHI="${LOCALAPPDATA}High"

# shellcheck disable=2154
CONF="$USERPROFILE/.config"
PWSH="$USERPROFILE/Documents/PowerShell"
PS1="$CONF/powershell/Microsoft.PowerShell_profile.ps1"
PSPROFILE="$PWSH/Microsoft.PowerShell_profile.ps1"

# shellcheck disable=2154
CURL="$APPDATA/.curlrc"
BAT="$CONF/bat"
BTM="$CONF/bottom"
GPG="$CONF/gnupg"

mkdir -v -p -- "$USERPROFILE/.local" "$LOCALHI" "$PWSH"
if ! [[ -L $CONF ]]; then
  powershell.exe New-Item -ItemType Junction -Path "$CONF" -Target "$LOCALAPPDATA"
fi
mkdir -v -p -- "$BAT" "$BTM" "$GPG"

declare -A -- LINKS=()
LINKS=(
  ["$APPDATA/bat"]="$BAT"
  ["$APPDATA/bottom"]="$BTM"
  ["$USERPROFILE/.cache"]="$WINTMP"
  ["$USERPROFILE/.gnupg"]="$GPG"
  ["$USERPROFILE/.local/opt"]="$LOCALHI"
  ["$USERPROFILE/.local/share"]="$APPDATA"
  ["$USERPROFILE/.local/state"]="$LOCALLO"
)

for FROM in "${!LINKS[@]}"; do
  TO="${LINKS["$FROM"]}"
  if ! [[ -L $FROM ]]; then
    P_FROM="$(dirname -- "$FROM")"
    P_TO="$(dirname -- "$TO")"
    mkdir -v -p -- "$P_FROM" "$P_TO"
    FROM="$(cygpath --windows -- "$FROM")"
    TO="$(cygpath --windows -- "$TO")"
    powershell.exe New-Item -ItemType Junction -Path "$FROM" -Target "$TO"
  fi
done

if [[ -f $PS1 ]] && ! [[ -L $PSPROFILE ]]; then
  ln -v -snf -- "$PS1" "$PSPROFILE"
fi

if [[ -d "$CONF/curl" ]] && ! [[ -L $CURL ]]; then
  ln -v -snf -- "$CONF/curl/.curlrc" "$CURL"
fi
