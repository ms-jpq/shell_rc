#################### ########### ####################
#################### Path Region ####################
#################### ########### ####################

if [[ "$SHLVL" -eq 1 ]]
then
  export PATH="$XDG_CONFIG_HOME/bin:$PATH"
  export PATH="$XDG_CONFIG_HOME/scripts:$PATH"
fi
