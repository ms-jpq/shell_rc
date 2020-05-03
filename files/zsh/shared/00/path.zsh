#################### ########### ####################
#################### Path Region ####################
#################### ########### ####################

if [[ "$SHLVL" -eq 1  ]]
then
  export PATH="$XDG_CONFIG_HOME/scripts:$PATH"
  export PATH="$HOME/.bin:$PATH"
fi
