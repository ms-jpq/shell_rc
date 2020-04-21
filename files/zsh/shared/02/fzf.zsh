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
                         --bind alt-a:select-all \
                         --bind alt-l:deselect-all"

export FZF_DEFAULT_COMMAND='fd -HI -t f'

export FZF_PREVIEW="test -d {} \
                    && exa \
                    --color=always \
                    --group-directories-first \
                    -T -L 2 {} \
                    || bat --color always {}"

export FZF_TMUX_HEIGHT='100%'


alias f='fzf'
alias fp='f --preview $FZF_PREVIEW'


d() {
  local dest="$(FZF_DEFAULT_COMMAND='fd -HI -t d -t l' fp -q "${*:-""}")"
  cd "$dest" || return 1
}
