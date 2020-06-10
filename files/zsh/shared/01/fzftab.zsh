#################### ############## ####################
#################### FZF Tab Region ####################
#################### ############## ####################

export FZF_TAB_OPTS=(
  -m
  --ansi
  --no-color
  --tiebreak=begin
  --expect='$continuous_trigger' # For continuous completion
  --nth=2,3 --delimiter='\x00'  # Don't search prefix
  '--query=$query'   # $query will be expanded to query string at runtime.
  '--header-lines=$#headers' # $#headers will be expanded to lines of headers at runtime
)


# INTI #
source "$ZDOTDIR/fzf-tab/fzf-tab.zsh"
# INIT #

