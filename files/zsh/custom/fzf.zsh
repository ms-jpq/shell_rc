#################### ########## ####################
#################### FZF Region ####################
#################### ########## ####################

export FZF_COLOUR="light"

export FZF_DEFAULT_OPTS="--color $FZF_COLOUR \
                         --reverse \
                         --no-height \
                         --border \
                         --cycle \
                         --bind ctrl-s:toggle-sort"

export FZF_DEFAULT_COMMAND="fd -HI -t f"

export FZF_PREVIEW="test -d {} \
                    && exa \
                    --color=always \
                    --group-directories-first \
                    -T -L 2 {} \
                    || bat --color always {}"

export FZF_TMUX_HEIGHT="100%"


alias f='fzf'
alias fp='f --preview $FZF_PREVIEW'


unalias z
z() {
  local A="$(_z -l "$@" 2>&1)"
  local B="$(echo "$A" | sed -e "s/^[0-9|\.]\+[ ]\+//" -e "/^common:[ ]\+/d")"
  if [[ -z "$B" ]]
  then
    echo "no such file or directory: $*"
  else
    local C="$(echo "$B" | fp -1 +s --tac)"
    cd "$C" || return 1
  fi
}
