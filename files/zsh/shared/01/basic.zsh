#################### ########### ####################
#################### Core Region ####################
#################### ########### ####################

export PAGER='less'
export LESS='-KQRJi~ --mouse --tabs=2 --no-histdups'
export LESSHISTFILE="$XDG_CACHE_HOME/less_hist"


# Safety
alias rm='rm -I'
alias mv='mv -i'
alias cp='cp -i'
# Safety


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


export WGETRC="$XDG_CONFIG_HOME/wgetrc"


export MANPAGER='nvim +Man!'
export MANWIDTH='99999'
