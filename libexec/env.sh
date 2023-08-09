#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

case "$OSTYPE" in
linux*)
  # shellcheck disable=SC1091
  source -- /etc/os-release
  MEMINFO_KB="$(awk '/MemTotal/ { print $2 }' </proc/meminfo)"
  MEMINFO=$((MEMINFO_KB * 1024))
  MAKE='gmake'
  RSYNC='rsync'
  ;;
darwin*)
  ID="$(sw_vers -productName)"
  VERSION_ID="$(sw_vers -productVersion)"
  VERSION_CODENAME="$VERSION_ID"
  MEMINFO="$(sysctl -n hw.memsize)"
  MAKE='gmake'
  RSYNC='rsync'
  ;;
msys)
  trim() {
    local -- v
    v="$(tr --delete '\r' | tr --delete $'\n')"
    v="${v#* }"
    v="${v##+([[:space:]])}"
    v="${v%%+([[:space:]])}"
    printf -- '%s' "$v"
  }

  # shellcheck disable=2154
  HOME="$USERPROFILE"
  ID="$(wmic os get Caption | trim)"
  VERSION_ID="$(wmic os get Version | trim)"
  VERSION_CODENAME="$VERSION_ID"
  MEMINFO="$(wmic ComputerSystem get TotalPhysicalMemory | trim)"
  # shellcheck disable=SC2154
  MAKE="$SYSTEMDRIVE/msys64/usr/bin/make"
  RSYNC="$SYSTEMDRIVE/msys64/usr/bin/rsync"
  ;;
*)
  exit 1
  ;;
esac

tee <<-EOF
ENV_HOME=$(printf -- '%q' "$HOME")
ENV_HOSTNAME=$(printf -- '%q' "$HOSTNAME")
ENV_HOSTTYPE=$(printf -- '%q' "$HOSTTYPE")
ENV_ID=$(printf -- '%q' "$ID")
ENV_MACHTYPE=$(printf -- '%q' "$MACHTYPE")
ENV_MAKE=$(printf -- '%q' "$MAKE")
ENV_MEMINFO=$(printf -- '%q' "$MEMINFO")
ENV_OSTYPE=$(printf -- '%q' "$OSTYPE")
ENV_RSYNC=$(printf -- '%q' "$RSYNC")
ENV_VERSION_CODENAME=$(printf -- '%q' "$VERSION_CODENAME")
ENV_VERSION_ID=$(printf -- '%q' "$VERSION_ID")
EOF
