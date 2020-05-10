#################### ############## ####################
#################### FZF Tab Region ####################
#################### ############## ####################

# INTI #
source "$ZDOTDIR/fzf-tab/fzf-tab.zsh"
# INIT #


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
