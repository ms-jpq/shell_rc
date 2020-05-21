#################### ########## ####################
#################### FZF Region ####################
#################### ########## ####################

export FZF_COLOUR="--color=light \
                   --color=bg+:#dee2f7"

export FZF_DEFAULT_OPTS="$FZF_COLOUR \
                         --reverse \
                         --no-height \
                         --border \
                         --cycle \
                         --tabstop=4 \
                         --preview-window right:wrap \
                         --bind ctrl-space:toggle \
                         --bind btab:up \
                         --bind tab:down \
                         --bind alt-p:toggle+up \
                         --bind alt-n:toggle+down \
                         --bind alt-a:select-all \
                         --bind alt-l:deselect-all"

export FZF_PREVIEW="test -d {} \
                    && exa \
                    --color=always \
                    --group-directories-first \
                    -T -L 2 {} \
                    || bat --color always {}"



export FZF_FD_PREFIX='fd -HL'

export FZF_DEFAULT_COMMAND="$FZF_FD_PREFIX -t f -t l"
export FZF_COMPLETION_OPTS="$(printf "--preview '%s'" "$FZF_PREVIEW")"

export FZF_ALT_C_COMMAND="$FZF_FD_PREFIX -0 -I -t d"
export FZF_ALT_C_OPTS="$FZF_COMPLETION_OPTS --read0"

export FZF_CTRL_T_COMMAND="$FZF_FD_PREFIX -0"
export FZF_CTRL_T_OPTS="$FZF_COMPLETION_OPTS --read0"


export FZF_TMUX_HEIGHT='100%'


alias f='fzf'
alias fp='fzf --preview $FZF_PREVIEW'


d() {
  local dest="$(FZF_DEFAULT_COMMAND="$FZF_ALT_C_COMMAND" fp --read0 -q "${*:-""}")"
  cd "$dest" || return 1
}


#################### ################ ####################
#################### Overwrite Region ####################
#################### ################ ####################

_fzf_compgen_path() {
  fd -HL -t d -t f -t l "$1"
}


_fzf_compgen_dir() {
  fd -HL -t d "$1"
}


# INTI #
source "$ZDOTDIR/fzf/shell/key-bindings.zsh"
source "$ZDOTDIR/fzf/shell/completion.zsh"
# INIT #
