#################### ############# ####################
#################### Go Env Region ####################
#################### ############# ####################

export GOPATH="$XDG_DATA_HOME/go"
if [[ "$SHLVL" -eq 1 ]]
then
  export PATH="$GOPATH/bin:$PATH"
fi
