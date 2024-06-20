#!/usr/bin/env -S -- bash

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
  --bind ctrl-w:select-all
  --bind ctrl-l:deselect-all
  --color light
  --color bg+:'#dfdfdf'
)
printf -v FZF_DEFAULT_OPTS -- '%q ' "${_fzf_default_opts[@]}"
unset -- _fzf_default_opts
export -- FZF_DEFAULT_OPTS

_fzf_default_command=(
  fd
  --hidden
  --no-ignore-parent
  # --follow
  --type file
)
printf -v FZF_DEFAULT_COMMAND -- '%q ' "${_fzf_default_command[@]}"
unset -- _fzf_default_command
export -- FZF_DEFAULT_COMMAND

_fzf_alt_c_command=(
  command -- fd
  --print0
  --hidden
  --no-ignore-parent
  # --follow
  --type directory
)
# shellcheck disable=SC2034
printf -v FZF_ALT_C_COMMAND -- '%q ' "${_fzf_alt_c_command[@]}"
unset -- _fzf_alt_c_command

_fzf_ctrl_t_command=(
  command -- fd
  --print0
  --hidden
  --no-ignore-parent
  # --follow
)
# shellcheck disable=SC2034
printf -v FZF_CTRL_T_COMMAND -- '%q ' "${_fzf_ctrl_t_command[@]}"
unset -- _fzf_ctrl_t_command

_fzf_preview=(
  --preview "$(printf -- '%q' "$XDG_CONFIG_HOME/zsh/libexec/preview.sh") {}"
)
_fzf_alt_c_opts=(
  --read0
  "${_fzf_preview[@]}"
)
# shellcheck disable=SC2034
printf -v FZF_ALT_C_OPTS -- '%q ' "${_fzf_alt_c_opts[@]}"
unset -- _fzf_alt_c_opts
# shellcheck disable=SC2034
FZF_CTRL_T_OPTS="$FZF_ALT_C_OPTS"

_fzf_compgen_path() {
  local -- local_opts=(
    command -- fd
    --hidden
    --no-ignore-parent
    # --follow
    --type directory
    --type file
  )
  "${local_opts[@]}" "$1"
}

_fzf_compgen_dir() {
  local -- local_opts=(
    command -- fd
    --hidden
    --no-ignore-parent
    # --follow
    --type directory
  )
  "${local_opts[@]}" "$1"
}
