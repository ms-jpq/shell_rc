#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

RESET=(
  $'\033[>4m'    # Extended keyboard
  $'\033[?69l'   # Horizontal margins
  $'\033[?1002l' # Mouse dragging
  $'\033[?1003l' # Mouse motion
  $'\033[?1004l' # Focus events
  $'\033[?1005l' # UTF-8 mouse encoding
  $'\033[?1015l' # URXVT mouse encoding
  $'\033[?1016l' # Mouse pixel coordinates
  $'\033[?2004l' # Bracketed paste
  $'\033[r'      # Vertical margins
)

stty sane
tput -S << 'EOF'
rmcup
cnorm
sgr0
rmacs
rmkx
XM 0
EOF

if [[ -t 2 ]]; then
  IFS=''
  printf -- '%s' "${RESET[*]}" >&2
fi
