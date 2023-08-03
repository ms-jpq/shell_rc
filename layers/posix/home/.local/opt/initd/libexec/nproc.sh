#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

case "$OSTYPE" in
darwin*)
  sysctl -n hw.physicalcpu
  ;;
linux*)
  nproc
  ;;
msys*)
  if command -v -- nproc >/dev/null; then
    nproc
  else
    "${0%/*}/pwsh.sh" 'Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -ExpandProperty NumberOfProcessors'
  fi
  ;;
*)
  exit 1
  ;;
esac
