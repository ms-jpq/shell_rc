#!/usr/bin/env -S -- bash

d() {
  local -- default_cmd=(
    fd
    --hidden
    --follow
    --print0
    --type directory
  )
  local -- dest=
  dest="$(FZF_DEFAULT_COMMAND="$(printf -- '%q ' "${default_cmd[@]}")" fp --read0 --query "${*:-}")"
  cd -- "$dest" || return 1
}