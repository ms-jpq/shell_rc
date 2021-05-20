#!/usr/bin/env bash

#################### ########## ####################
#################### FZF Region ####################
#################### ########## ####################


_fzf_default_opts=(
  --reverse
  --no-height
  --border
  --cycle
  --tabstop=2
  --preview-window=right:wrap
  --bind=ctrl-space:toggle
  --bind=tab:down
  --bind=btab:up
  --bind=shift-down:toggle+down
  --bind=shift-up:toggle+up
  --bind=shift-left:preview-up
  --bind=shift-right:preview-down
  --bind=alt-a:select-all
  --bind=alt-l:deselect-all
  --color=light
  --color=bg+:'#dfdfdf'
)
export FZF_DEFAULT_OPTS="${_fzf_default_opts[*]}"
unset _fzf_default_opts

_fzf_preview='preview {}'
_fzf_default_command=(
  fd
  --type=file
  --type=symlink
)
export FZF_DEFAULT_COMMAND="${_fzf_default_command[*]}"
_fzf_preview_opts="--preview='$_fzf_preview'"
unset _fzf_default_command

_fzf_alt_c_command=(
  fd
  --print0
  --no-ignore
  --type=symlink
  --type=directory
)
export FZF_ALT_C_COMMAND="${_fzf_alt_c_command[*]}"
export FZF_ALT_C_OPTS="$_fzf_preview_opts --read0"
unset _fzf_alt_c_command

_fzf_ctrl_t_command=(
  fd
  --print0
  --no-ignore
)
export FZF_CTRL_T_COMMAND="${_fzf_ctrl_t_command[*]}"
export FZF_CTRL_T_OPTS="$_fzf_preview_opts --read0"
unset _fzf_preview_opts
unset _fzf_ctrl_t_command

export FZF_TMUX_HEIGHT='100%'


alias f='fzf'
alias fp="fzf --preview='$_fzf_preview'"


d() {
  local default_cmd=(
    fd
    --print0
    --type=directory
  )
  local dest="$(FZF_DEFAULT_COMMAND="${default_cmd[*]}" fp --read0 -q "${*:-""}")"
  cd "$dest" || return 1
}


#################### ################ ####################
#################### Overwrite Region ####################
#################### ################ ####################

_fzf_compgen_path() {
  local local_opts=(
    --type=directory
    --type=symlink
    --type=file
  )
  fd "${local_opts[@]}" "$1"
}


_fzf_compgen_dir() {
  local local_opts=(
    --type=directory
  )
  fd "${local_opts[@]}" "$1"
}

# INTI #
source "$ZDOTDIR/fzf/shell/key-bindings.zsh"
source "$ZDOTDIR/fzf/shell/completion.zsh"
# INIT #
