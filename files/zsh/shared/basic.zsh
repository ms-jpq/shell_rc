#################### ########### ####################
#################### Core Region ####################
#################### ########### ####################

export PAGER='less'
export LESS="--quit-on-intr \
             --quit-if-one-screen \
             --mouse \
             --RAW-CONTROL-CHARS \
             --tilde \
             --tabs=2 \
             --QUIET \
             --ignore-case \
             --no-histdups"


# Safety
alias rm='rm -I'
alias mv='mv -i'
alias cp='cp -i'
# Safety


alias mkdir='mkdir -p'

alias cls='clear'
alias sudo='sudo -E '
alias cmd='command '


export TIME_STYLE='long-iso'
alias ls='exa --group-directories-first --icons -hF'
alias l='ls -1'
alias ll='ls -lg'
tree() {
  ls -T --level="${1:-2}"
}


export BAT_THEME=GitHub
# export BAT_THEME=ansi-dark
export BAT_STYLE=plain
alias cat='bat'


paths() {
  export PATH="$(command paths "$@")"
}

