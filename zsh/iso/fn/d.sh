#!/usr/bin/env -S -- bash

d() {
  local -- default_cmd=(
    fd
    --hidden
    --follow
    --print0
    --type directory
  )
  local -- dst=
  dst="$(FZF_DEFAULT_COMMAND="$(printf -- '%q ' "${default_cmd[@]}")" fp --read0 --query "${*:-}")"
  cd -- "$dst" || return 1
}
