#################### ########## ####################
#################### ZSH Region ####################
#################### ########## ####################

set -o pipefail
set -o autopushd pushdignoredups pushdminus pushdsilent pushdtohome

autoload zmv


#################### ################ ####################
#################### Powerline Region ####################
#################### ################ ####################
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]
then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
source $HOME/.p10k.zsh


#################### ########## ####################
#################### OMZ Region ####################
#################### ########## ####################
ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=powerlevel10k/powerlevel10k

DISABLE_UPDATE_PROMPT=true
HYPHEN_INSENSITIVE=true
COMPLETION_WAITING_DOTS=true


#################### ################## ####################
#################### AutoSuggest Region ####################
#################### ################## ####################
zle -N autosuggest-accept
bindkey '^ ' autosuggest-accept
ZSH_AUTOSUGGEST_USE_ASYNC=true
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=4"
ZSH_AUTOSUGGEST_ACCEPT_WIDGETS=(autosuggest-accept)


#################### ############## ####################
#################### History Region ####################
#################### ############## ####################
zle -N history-substring-search-up
zle -N history-substring-search-down
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
HISTORY_SUBSTRING_SEARCH_FUZZY=true
HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=true


#################### ########## ####################
#################### OMZ Region ####################
#################### ########## ####################
plugins=(zsh-syntax-highlighting
         zsh-completions
         zsh-autosuggestions
         history-substring-search
         fzf
         ripgrep
         rsync
         mosh
         autojump
         colorize
         ansible
         docker
         docker-compose
         kubectl
         vagrant)
autoload -U compinit && compinit
source $ZSH/oh-my-zsh.sh
