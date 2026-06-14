#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

# https://junegunn.github.io/fzf/tips/ripgrep-integration/
RG=(
  rg
  --with-filename
  --column
  --line-number
  --fixed-strings
  --color always
  # --null
  --
)
CHANGE="${RG[*]@Q}"
_q="$*"
START="$CHANGE ${_q@Q}"

BAT=(
  bat
  --color always
  --highlight-line
)
PREVIEW="${BAT[*]@Q}"

EDIT=(nvim -c copen -q)

MULT=()
if [[ -t 1 ]]; then
  MULT+=(--multi)
  OPENER="${EDIT[*]@Q}"
else
  OPENER='printf -- %s'
fi

FZF_ARGS=(
  fzf
  --disabled
  # --read0
  --ansi
  "${MULT[@]}"
  --delimiter ':'
  --preview "$PREVIEW {2} -- {1}"
  --preview-window '~3,+{2}+3/3'
  --bind "start:reload:$START || :"
  --bind "change:reload:$CHANGE {q} || :"
  --bind "enter:become:$OPENER {+f1,2,3,4}"
  --query "$*"
)

exec -- "${FZF_ARGS[@]}"
