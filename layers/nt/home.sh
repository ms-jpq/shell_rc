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

CONF="$USERPROFILE/.config"
PWSH="$USERPROFILE/Documents/PowerShell"

mkdir -v -p -- "$USERPROFILE/.local" "$APPDATA" "$LOCALAPPDATA" "$LOCALLO" "$LOCALHI" "$PWSH"

link() {
  local -- SRC="$1" DST="$2"

  if ! [[ -d "$DST" ]]; then
    SRC="$(/usr/bin/cygpath --absolute --windows "$SRC")"
    DST="$(/usr/bin/cygpath --absolute --windows "$DST")"
    if [[ -d "$SRC" ]]; then
      printf -v LINK -- 'mklink /j "%s" "%s"' "$DST" "$SRC"
    else
      printf -v LINK -- 'mklink "%s" "%s"' "$DST" "$SRC"
    fi
    printf -- '%s\n' "$LINK"
    cmd "$LINK"
    # ln -v -sf -- "$SRC" "$DST" || true
  fi
}

link "$APPDATA" "$CONF"
link "$LOCALAPPDATA" "$USERPROFILE/.local/share"
link "$TEMP" "$USERPROFILE/.cache"
link "$LOCALLO" "$USERPROFILE/.local/state"
link "$LOCALHI" "$USERPROFILE/.local/opt"
link "$USERPROFILE/.config/powershell/Microsoft.PowerShell_profile.ps1" "$PWSH/Microsoft.PowerShell_profile.ps1"
