#!/usr/bin/env -S -- bash

set -Eeu
set -o pipefail
shopt -s dotglob
shopt -s nullglob
shopt -s extglob
shopt -s failglob

case "$OSTYPE" in
linux*)
  # shellcheck disable=SC1091
  source -- /etc/os-release
  NPROC="$(nproc)"
  MEMINFO="$(awk '/MemTotal/ { print $2 }' </proc/meminfo)"
  ;;
darwin*)
  ID="$(sw_vers -productName)"
  VERSION_ID="$(sw_vers -productVersion)"
  VERSION_CODENAME="$VERSION_ID"
  NPROC="$(sysctl -n hw.physicalcpu)"
  MEMINFO_KB="$(sysctl -n hw.memsize)"
  MEMINFO=$((MEMINFO_KB * 1024))
  ;;
*msys*)
  ID="$(wmic os get Caption)"
  VERSION_ID="$(wmic os get Version)"
  VERSION_CODENAME="$VERSION_ID"
  # shellcheck disable=SC2154
  NPROC="$NUMBER_OF_PROCESSORS"
  MEMINFO="$(wmic ComputerSystem get TotalPhysicalMemory)"
  ;;
*) ;;
esac

tee <<-EOF
{
  "HOME": "$HOME",
  "HOSTNAME": "$HOSTNAME",
  "HOSTTYPE": "$HOSTTYPE",
  "ID": "$ID",
  "MACHTYPE": "$MACHTYPE",
  "MEMINFO": "$MEMINFO",
  "NPROC": "$NPROC",
  "OSTYPE": "$OSTYPE",
  "VERSION_CODENAME": "$VERSION_CODENAME",
  "VERSION_ID": "$VERSION_ID"
}
EOF
