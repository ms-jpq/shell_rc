#################### ########### ####################
#################### Ruby Region ####################
#################### ########### ####################

export GEM_HOME="$HOME/.gems"
export PATH="$HOME/.gems/bin:$PATH"

if [[ -x "$(command -v rbenv)" ]]
then
  eval "$(rbenv init -)"
fi
