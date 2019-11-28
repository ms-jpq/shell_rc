#################### ########## ####################
#################### ZSH Region ####################
#################### ########## ####################

set -o pipefail
set -o histignoredups incappendhistory sharehistory extended_history
set -o autopushd pushdignoredups pushdminus pushdsilent pushdtohome


#################### ################ ####################
#################### Powerline Region ####################
#################### ################ ####################
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


#################### ########## ####################
#################### OMZ Region ####################
#################### ########## ####################
ZSH="$HOME/.oh-my-zsh"
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
ZSH_THEME="powerlevel10k/powerlevel10k"
DISABLE_UPDATE_PROMPT=true
HYPHEN_INSENSITIVE=true


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
         thefuck)
autoload -U compinit && compinit
source $ZSH/oh-my-zsh.sh


#################### ################ ####################
#################### Powerline Region ####################
#################### ################ ####################
source ~/.p10k.zsh


#################### ############# ####################
#################### iTerm2 Region ####################
#################### ############# ####################
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
