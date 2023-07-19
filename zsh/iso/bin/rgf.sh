#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

RG_ARGS="${_RG_ARGS:-}"

if [[ -z "$RG_ARGS" ]]; then
  export -- _RG_ARGS=""
  _RG_ARGS="$(mktemp)"
  ARGS=(
    --line-buffered
    --files-with-matches
    --null
    "$@"
  )
  FZF_ARGS=(
    --read0
    --print0
    --preview='{f}'
  )
  for ARG in "$@"; do
    printf -- '%s\0' "$ARG" >>"$_RG_ARGS"
  done
  rg "${ARGS[@]}" | SHELL="$0" fzf "${FZF_ARGS[@]}"
else
  ARGS=(
    --color=always
    --line-number
    --context=3
    --context-separator="$("$ZDOTDIR/libexec/hr.sh" '-' "$FZF_PREVIEW_COLUMNS")"
  )
  readarray -t -d $'\0' -- ENV_ARGS <"$RG_ARGS"
  readarray -t -d $'\0' -- RG_PATH <"$2"
  exec -- rg "${ARGS[@]}" "${ENV_ARGS[@]}" -- "${RG_PATH[@]}"
fi
