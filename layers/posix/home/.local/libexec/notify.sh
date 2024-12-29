#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

T=0
case "$TERM" in
tmux*)
  T=1
  ;;
*) ;;
esac

if ((T)); then
  # TMUX wrap start
  printf -- '\ePtmux;'
fi

{
  if ((T)); then
    # TMUX escape `ESC`
    printf -- '\e'
  fi

  # OSC99 start
  printf -- '\e]99;i=1:d=0;'
  # OSC99 title
  printf -- '%s' "$*"

  if ((T)); then
    # TMUX escape `ESC`
    printf -- '\e'
  fi

  # OSC52 end
  # shellcheck disable=SC1003
  printf -- '\e\\'
}

{
  if ((T)); then
    # TMUX escape `ESC`
    printf -- '\e'
  fi

  # OSC99 start
  printf -- '\e]99;i=1:p=body;'
  # OSC99 body
  tee --

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
