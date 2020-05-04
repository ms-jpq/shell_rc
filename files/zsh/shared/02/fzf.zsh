#################### ########## ####################
#################### FZF Region ####################
#################### ########## ####################

export FZF_COLOUR='light'

export FZF_DEFAULT_OPTS="--color $FZF_COLOUR \
                         --reverse \
                         --no-height \
                         --border \
                         --cycle \
                         --preview-window right:wrap \
                         --bind btab:up \
                         --bind tab:down \
                         --bind ctrl-space:toggle \
                         --bind alt-a:select-all \
                         --bind alt-l:deselect-all"

export FZF_PREVIEW="test -d {} \
                    && exa \
                    --color=always \
                    --group-directories-first \
                    -T -L 2 {} \
                    || bat --color always {}"



export FZF_FD_PREFIX='fd -HIL'

export FZF_DEFAULT_COMMAND="$FZF_FD_PREFIX -t f -t l"
export FZF_COMPLETION_OPTS="$(printf "--preview '%s'" "$FZF_PREVIEW")"

export FZF_ALT_C_COMMAND="$FZF_FD_PREFIX -0 -t d -t l"
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
