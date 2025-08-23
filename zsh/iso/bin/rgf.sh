#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

# https://junegunn.github.io/fzf/tips/ripgrep-integration/
RG=(
  rg
  --column
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

# shellcheck disable=SC2154
EDIT=(
  "$EDITOR"
  --
)
printf -v OPENER -- '%q ' "${EDIT[@]}"

FZF_ARGS=(
  fzf
  --disabled
  # --read0
  --ansi
  --multi
  --delimiter ':'
  --preview "$PREVIEW {2} -- {1}"
  --bind "start:reload:$CHANGE '' || :"
  --bind "change:reload:$CHANGE {q} || :"
  --bind "enter:become:$OPENER {+1}"
)

"${FZF_ARGS[@]}" < /dev/null
