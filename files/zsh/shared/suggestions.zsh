#################### ################## ####################
#################### AutoSuggest Region ####################
#################### ################## ####################

ZSH_AUTOSUGGEST_USE_ASYNC=true
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=4'
ZSH_AUTOSUGGEST_ACCEPT_WIDGETS=(autosuggest-accept)


# INTI #
source "$ZDOTDIR/zsh-autosuggestions/zsh-autosuggestions.zsh"
# INIT #


bindkey '^ ' autosuggest-accept

