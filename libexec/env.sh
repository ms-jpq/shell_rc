#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

case "$OSTYPE" in
linux*)
  # shellcheck disable=SC1091
  source -- /etc/os-release
  NPROC="$(nproc)"
  MEMINFO_KB="$(awk '/MemTotal/ { print $2 }' </proc/meminfo)"
  MEMINFO=$((MEMINFO_KB * 1024))
  MAKE="$(command -v -- gmake)"
  ;;
darwin*)
  ID="$(sw_vers -productName)"
  VERSION_ID="$(sw_vers -productVersion)"
  VERSION_CODENAME="$VERSION_ID"
  NPROC="$(sysctl -n hw.physicalcpu)"
  MEMINFO="$(sysctl -n hw.memsize)"
  MAKE="$(command -v -- gmake)"
  ;;
msys)
  if command -v -- pwsh >/dev/null; then
    PSH=pwsh
  else
    PSH=powershell
  fi

  trim() {
    local -- v
    v="$(tr --delete '\r' | tr --delete $'\n')"
    v="${v#* }"
    v="${v##+([[:space:]])}"
    v="${v%%+([[:space:]])}"
    printf -- '%s' "$v"
  }

  # shellcheck disable=2154
  HOME="$HOMEDRIVE$HOMEPATH"
  ID="$(wmic os get Caption | trim)"
  VERSION_ID="$(wmic os get Version | trim)"
  VERSION_CODENAME="$VERSION_ID"
  NPROC="$("$PSH" -command '(Get-WmiObject -Class Win32_Processor).NumberOfCores')"
  MEMINFO="$(wmic ComputerSystem get TotalPhysicalMemory | trim)"
  # shellcheck disable=SC2154
  MAKE="$SystemDrive/msys2/usr/bin/make"
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
ENV_NPROC=$(printf -- '%q' "$NPROC")
ENV_OSTYPE=$(printf -- '%q' "$OSTYPE")
ENV_VERSION_CODENAME=$(printf -- '%q' "$VERSION_CODENAME")
ENV_VERSION_ID=$(printf -- '%q' "$VERSION_ID")
EOF
