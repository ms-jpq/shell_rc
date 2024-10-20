#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

SEP=$'\4'
RG_ARGS="${_RG_ARGS:-}"

if [[ -z $RG_ARGS ]]; then
  export -- _RG_ARGS=""
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
  IFS="$SEP"

  if (($#)); then
    rg "${ARGS[@]}" 2>&1 | SHELL="$0" _RG_ARGS="$*" fzf "${FZF_ARGS[@]}"
  else
    rg
  fi
else
  ARGS=(
    --color=always
    --line-number
    --context=3
    --context-separator="$("$XDG_CONFIG_HOME/zsh/libexec/hr.sh" '-' "$FZF_PREVIEW_COLUMNS")"
  )
  readarray -t -d "$SEP" -- ENV_ARGS < <(printf -- '%s' "$RG_ARGS")
  readarray -t -d '' -- RG_PATH < "$2"
  exec -- rg "${ARGS[@]}" "${ENV_ARGS[@]}" -- "${RG_PATH[@]}"
fi
