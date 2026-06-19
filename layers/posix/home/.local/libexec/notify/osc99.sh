#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

TITLE="$1"
BODY="${2-}"

T=0
case "$TERM" in
tmux*)
  T=1
  ;;
*) ;;
esac

if [[ -v TMUX_PANE ]]; then
  T=1
fi

if ((T)); then
  # TMUX wrap start
  printf -- '\ePtmux;'
fi

# https://sw.kovidgoyal.net/kitty/desktop-notifications/
ID=1

{
  if ((T)); then
    # TMUX escape `ESC`
    printf -- '\e'
  fi

  # OSC99 start
  printf -- '\e]99;e=1:i=%s:d=0:p=title;' "$ID"
  # OSC99 title
  base64 -w 0 <<< "$TITLE"

  if ((T)); then
    # TMUX escape `ESC`
    printf -- '\e'
  fi

  # OSC99 end
  # shellcheck disable=SC1003
  printf -- '\e\\'
}

{
  if ((T)); then
    # TMUX escape `ESC`
    printf -- '\e'
  fi

  # OSC99 start
  printf -- '\e]99;e=1:i=%s:d=1:p=body;' "$ID"
  # OSC99 body
  base64 -w 0 <<< "$BODY"

  if ((T)); then
    # TMUX escape `ESC`
    printf -- '\e'
  fi

  # OSC99 end
  # shellcheck disable=SC1003
  printf -- '\e\\'
}

if ((T)); then
  # TMUX wrap end
  # shellcheck disable=SC1003
  printf -- '\e\\'
fi
