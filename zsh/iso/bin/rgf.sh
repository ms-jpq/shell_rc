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
printf -v CHANGE -- '%q ' "${RG[@]}"
BAT=(
  bat
  --color always
  --highlight-line
)
printf -v PREVIEW -- '%q ' "${BAT[@]}"

EDIT=()
if [[ $* == --tmux ]]; then
  EDIT+=(tmux new-window -a -c '#{pane_current_path}' --)
fi

# shellcheck disable=SC2154
EDIT+=(nvim -c copen -q)

MULT=()
if [[ -t 1 ]]; then
  MULT+=(--multi)
  printf -v OPENER -- '%q ' "${EDIT[@]}"
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
  --bind "start:reload:$CHANGE '' || :"
  --bind "change:reload:$CHANGE {q} || :"
  --bind "enter:become:$OPENER {+f1,2,3,4}"
  --query "$*"
)

"${FZF_ARGS[@]}" < /dev/null
