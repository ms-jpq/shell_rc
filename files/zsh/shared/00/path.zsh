#################### ########### ####################
#################### Path Region ####################
#################### ########### ####################

if [[ "$SHLVL" -eq 1 ]]
then
  export PATH="$XDG_CONFIG_HOME/zsh/bin:$PATH"
  export PATH="$XDG_CONFIG_HOME/scripts:$PATH"
  export PATH="$XDG_DATA_HOME/bin:$PATH"
fi
