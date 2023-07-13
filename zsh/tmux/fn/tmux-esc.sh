#!/usr/bin/env -S -- bash

tmux-esc() {
  local AWK LS

  read -r -d '' -- AWK <<-'EOF' || true
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
EOF

  if [[ -v TMUX ]]; then
    if [[ -v SSH_TTY ]]; then
      LS="$(awk "$AWK")"
      awk "$AWK" <<<"$LS"
    else
      awk "$AWK"
    fi
  elif [[ -v SSH_TTY ]]; then
    awk "$AWK"
  else
    tee
  fi
}
