#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

case "$OSTYPE" in
linux*)
  # shellcheck disable=SC1091
  source -- /etc/os-release
  NPROC="$(nproc)"
  MEMBYTES_KB="$(awk '/MemTotal/ { print $2 }' < /proc/meminfo)"
  MEMBYTES=$((MEMBYTES_KB * 1024))
  ;;
darwin*)
  ID="$(sw_vers -productName)"
  VERSION_ID="$(sw_vers -productVersion)"
  VERSION_CODENAME="$VERSION_ID"
  NPROC="$(sysctl -n hw.physicalcpu)"
  MEMBYTES="$(sysctl -n hw.memsize)"
  ;;
msys | cygwin)
  PATH="/usr/bin:$PATH"

  : "${USERPROFILE?}"
  HOME="$USERPROFILE"
  ID="$(powershell.exe 'Get-ComputerInfo | Select-Object -ExpandProperty WindowsEditionId' | tr -d -- '\r')"
  VERSION_ID="$(powershell.exe 'Get-ComputerInfo | Select-Object -ExpandProperty WindowsVersion' | tr -d -- '\r')"
  VERSION_CODENAME="$VERSION_ID"
  NPROC="$(nproc)"
  MEMBYTES="$(powershell.exe 'Get-WmiObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty TotalPhysicalMemory' | tr -d -- '\r')"
  ;;
*)
  exit 1
  ;;
esac

tee <<- EOF
ENV_HOME=${HOME@Q}
ENV_HOSTNAME=${HOSTNAME@Q}
ENV_HOSTTYPE=${HOSTTYPE@Q}
ENV_ID=${ID@Q}
ENV_MEMBYTES=${MEMBYTES@Q}
ENV_NPROC=${NPROC@Q}
ENV_OSTYPE=${OSTYPE@Q}
ENV_VERSION_CODENAME=${VERSION_CODENAME@Q}
ENV_VERSION_ID=${VERSION_ID@Q}
EOF
