#!/usr/bin/env bash

#################### ########## ####################
#################### FZF Region ####################
#################### ########## ####################


export -- FZF_TMUX_HEIGHT='100%'


_fzf_default_opts=(
  --reverse
  --no-height
  --border
  --cycle
  --tabstop 2
  --preview-window 60%:wrap
  --bind ctrl-space:toggle
  --bind tab:down
  --bind btab:up
  --bind shift-down:toggle+down
  --bind shift-up:toggle+up
  --bind shift-left:preview-up
  --bind shift-right:preview-down
  --bind alt-a:select-all
  --bind alt-l:deselect-all
  --color light
  --color bg+:'#dfdfdf'
)
FZF_DEFAULT_OPTS="$(join "${_fzf_default_opts[@]}")"
unset _fzf_default_opts
export -- FZF_DEFAULT_OPTS


_fzf_default_command=(
  fd
  --hidden
  --follow
  --type file
  --type symlink
)
FZF_DEFAULT_COMMAND="$(join "${_fzf_default_command[@]}")"
unset _fzf_default_command
export -- FZF_DEFAULT_COMMAND


_fzf_alt_c_command=(
  fd
  --print0
  --hidden
  --no-ignore
  --type symlink
  --type directory
)
# shellcheck disable=SC2034
FZF_ALT_C_COMMAND="$(join "${_fzf_alt_c_command[@]}")"
unset _fzf_alt_c_command


_fzf_ctrl_t_command=(
  fd
  --print0
  --hidden
  --no-ignore
)
# shellcheck disable=SC2034
FZF_CTRL_T_COMMAND="$(join "${_fzf_ctrl_t_command[@]}")"
unset _fzf_ctrl_t_command


_fzf_preview=(
  --preview "$(quote "$ZDOTDIR/shared/bin/preview") {}"
)
_fzf_alt_c_opts=(
  --read0
  "${_fzf_preview[@]}"
)
# shellcheck disable=SC2034
FZF_ALT_C_OPTS="$(join "${_fzf_alt_c_opts[@]}")"
unset _fzf_alt_c_opts
# shellcheck disable=SC2034
FZF_CTRL_T_OPTS="$FZF_ALT_C_OPTS"


#################### ################ ####################
#################### Overwrite Region ####################
#################### ################ ####################

_fzf_compgen_path() {
  local local_opts=(
    fd
    --type directory
    --type symlink
    --type file
  )
  "${local_opts[@]}" "$1"
}


_fzf_compgen_dir() {
  local local_opts=(
    fd
    --type directory
  )
  "${local_opts[@]}" "$1"
}

# INTI #
# shellcheck disable=SC1091
source -- "$ZDOTDIR/../fzf/shell/key-bindings.zsh"
# shellcheck disable=SC1091
source -- "$ZDOTDIR/../fzf/shell/completion.zsh"
# INIT #
