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
  MEMINFO_KB="$(awk '/MemTotal/ { print $2 }' </proc/meminfo)"
  MEMINFO=$((MEMINFO_KB * 1024))
  ;;
darwin*)
  ID="$(sw_vers -productName)"
  VERSION_ID="$(sw_vers -productVersion)"
  VERSION_CODENAME="$VERSION_ID"
  NPROC="$(sysctl -n hw.physicalcpu)"
  MEMINFO="$(sysctl -n hw.memsize)"
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
HOME=$(printf -- '%q' "$HOME")
HOSTNAME=$(printf -- '%q' "$HOSTNAME")
HOSTTYPE=$(printf -- '%q' "$HOSTTYPE")
ID=$(printf -- '%q' "$ID")
MACHTYPE=$(printf -- '%q' "$MACHTYPE")
MEMINFO=$MEMINFO
NPROC=$NPROC
OSTYPE=$(printf -- '%q' "$OSTYPE")
VERSION_CODENAME=$(printf -- '%q' "$VERSION_CODENAME")
VERSION_ID=$(printf -- '%q' "$VERSION_ID")
EOF