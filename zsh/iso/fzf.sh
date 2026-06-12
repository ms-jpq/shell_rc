#!/usr/bin/env -S -- bash

export -- FZF_TMUX_HEIGHT='100%'

# shellcheck disable=SC2154
export -- FZF_DEFAULT_OPTS_FILE="$XDG_CONFIG_HOME/fzf/rc.conf"

_zo_fzf_opts=(
  --no-sort
  --keep-right
  --exit-0
  --preview "$(printf -- '%q' "$XDG_CONFIG_HOME/zsh/libexec/preview.sh") {2..}"
)
printf -v _ZO_FZF_OPTS -- '%q ' "${_zo_fzf_opts[@]}"
unset -- _zo_fzf_opts
export -- _ZO_FZF_OPTS

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

_fzf_ctrl_r_opts=()
# shellcheck disable=SC2034
printf -v FZF_CTRL_R_OPTS -- '%q ' "${_fzf_ctrl_r_opts[@]}"
unset -- _fzf_ctrl_r_opts

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
