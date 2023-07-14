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
  ;;
darwin*)
  NPROC="$(sysctl -n hw.physicalcpu)"
  ;;
*msys*)
  # shellcheck disable=SC2154
  NPROC="$NUMBER_OF_PROCESSORS"
  ;;
*) ;;
esac

tee <<-EOF
{
  "HOME": "$HOME",
  "HOSTNAME": "$HOSTNAME",
  "HOSTTYPE": "$HOSTTYPE",
  "ID": "${ID:-""}",
  "MACHTYPE": "$MACHTYPE",
  "NPROC": "$NPROC",
  "OSTYPE": "$OSTYPE",
  "VERSION_CODENAME": "${VERSION_CODENAME:-""}",
  "VERSION_ID": "${VERSION_ID:-""}"
}
EOF
