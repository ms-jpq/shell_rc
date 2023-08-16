#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

SEP=$'\4'

EXECUTE_HEAD='execute::'
PREVIEW_HEAD='preview::'

ARGV=(
  --ansi
  --multi
  --preview-window=right:70%:wrap
  --read0
  --print0
  "--bind=return:become:$EXECUTE_HEAD{+f}"
  "--preview=$PREVIEW_HEAD{+f}"
)

if [[ -v __FZF_LR_ARGV__ ]]; then
  readarray -t -d "$SEP" -- ARGV < <(printf -- '%s' "$__FZF_LR_ARGV__")
  unset -- _FZF_LR_ARGV__
  FILE="$2"
  if [[ "$FILE" == "$EXECUTE_HEAD"* ]]; then
    FILE="${FILE#"$EXECUTE_HEAD"}"
    MODE='execute'
  else
    FILE="${FILE#"$PREVIEW_HEAD"}"
    MODE='preview'
  fi
  readarray -t -d $'\0' -- FS <"$FILE"
  IFS=$'\0'
  F="${FS[*]}"
  # shellcheck disable=SC2154
  SHELL="$__FZF_LR_SH__" SCRIPT_MODE="$MODE" exec -- "${ARGV[@]}" < <(printf -- '%s' "$F")
else
  IFS="$SEP"
  # shellcheck disable=SC2097,SC2098
  __FZF_LR_SH__="$SHELL" SHELL="$0" __FZF_LR_ARGV__="$*" LC_ALL=C exec -- fzf "${ARGV[@]}"
fi
