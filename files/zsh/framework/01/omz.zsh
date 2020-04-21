#################### ########## ####################
#################### OMZ Region ####################
#################### ########## ####################

ZSH="$ZDOTDIR/oh-my-zsh"
ZSH_THEME=powerlevel10k/powerlevel10k

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
         zsh-interactive-cd
         z
         fd
         ripgrep
         docker
         kubectl
         helm)
autoload -U compinit && compinit
source "$ZSH/oh-my-zsh.sh"
# Remove CD #
unset -f d
for i in $(seq 1 9)
do
  unalias "$i"
done
# Remove CD #
