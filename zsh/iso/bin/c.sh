#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

if [[ -t 0 ]]; then
  exit 2
fi

if [[ -v TMUX ]] && command -v -- tmux > /dev/null; then
  exec -- tmux load-buffer -w -- -
fi

if command -v -- pbcopy > /dev/null; then
  exec -- pbcopy
elif [[ -v WAYLAND_DISPLAY ]] && command -v -- wl-copy > /dev/null; then
  exec -- wl-copy
fi

T=0
case "$TERM" in
tmux*)
  T=1
  ;;
*) ;;
esac

if [[ -v TMUX ]]; then
  T=1
fi

if [[ -v NVIM_SERVERNAME ]]; then
  T=0
fi

if ((T)); then
  # TMUX wrap start
  printf -- '\ePtmux;'
fi

{
  if ((T)); then
    # TMUX escape `ESC`
    printf -- '\e'
  fi

  # OSC52 start
  printf -- '\e]52;c;'
  # OSC52 body
  base64 --wrap 0 -- "$@"

  if ((T)); then
    # TMUX escape `ESC`
    printf -- '\e'
  fi

  # OSC52 end
  # shellcheck disable=SC1003
  printf -- '\e\\'
}

if ((T)); then
  # TMUX wrap end
  # shellcheck disable=SC1003
  printf -- '\e\\'
fi
