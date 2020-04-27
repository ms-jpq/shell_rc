#################### ########## ####################
#################### OMZ Region ####################
#################### ########## ####################

ZSH="$ZDOTDIR/oh-my-zsh"
ZSH_THEME=powerlevel10k/powerlevel10k

DISABLE_AUTO_UPDATE=true
HYPHEN_INSENSITIVE=true
COMPLETION_WAITING_DOTS=true


#################### ################## ####################
#################### AutoSuggest Region ####################
#################### ################## ####################

zle -N autosuggest-accept
ZSH_AUTOSUGGEST_USE_ASYNC=true
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=4"
ZSH_AUTOSUGGEST_ACCEPT_WIDGETS=(autosuggest-accept)

# https://github.com/zsh-users/zsh-autosuggestions/issues/238#issuecomment-389324292
pasteinit() {
  OLD_SELF_INSERT=${${(s.:.)widgets[self-insert]}[2,3]}
  zle -N self-insert url-quote-magic
}

pastefinish() {
  zle -N self-insert $OLD_SELF_INSERT
}
zstyle :bracketed-paste-magic paste-init pasteinit
zstyle :bracketed-paste-magic paste-finish pastefinish


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
#################### Fzf Region ####################
#################### ########## ####################

FZF_TAB_OPTS=(
  --ansi
  --no-color
  --tiebreak=begin
  --expect='$continuous_trigger' # For continuous completion
  --nth=2,3 --delimiter='\x00'  # Don't search prefix
  -m
  '--query=$query'   # $query will be expanded to query string at runtime.
  '--header-lines=$#headers' # $#headers will be expanded to lines of headers at runtime
)


#################### ############## ####################
#################### Plugins Region ####################
#################### ############## ####################

plugins=(zsh-syntax-highlighting
         zsh-completions
         zsh-autosuggestions
         history-substring-search
         fzf
         fzf-tab
         z
         fd
         ripgrep
         colorize
         docker
         kubectl
         helm)
autoload -U compinit && compinit
source "$ZSH/oh-my-zsh.sh"


#################### ################ ####################
#################### Post-Init Region ####################
#################### ################ ####################

# Fix tmux
bindkey '^ ' autosuggest-accept
# Fix tmux


# Remove CD #
unset -f d
for i in $(seq 1 9)
do
  unalias "$i"
done
# Remove CD #
