#!/usr/bin/env -S -- bash

tmux-esc() {
  local AWK LS

  read -r -d '' -- AWK <<- 'AWK' || true
BEGIN { 
  printf("\x1BPtmux;")
}
{
  gsub("\x1B", "\x1B\x1B")
  printf($0)
}
END {
  printf("\x1B\\")
}
AWK

  if [[ -n ${TMUX:-} ]]; then
    if [[ -n ${SSH_TTY:-} ]]; then
      LS="$(awk "$AWK")"
      awk "$AWK" <<< "$LS"
    else
      awk "$AWK"
    fi
  elif [[ -n ${SSH_TTY:-} ]]; then
    awk "$AWK"
  else
    tee
  fi
}
