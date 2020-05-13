#################### ############### ####################
#################### Rust Env Region ####################
#################### ############### ####################

export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
export CARGO_HOME="$XDG_DATA_HOME/cargo"


if [[ "$SHLVL" -eq 1 ]]
then
  export PATH="$CARGO_HOME/bin:$PATH"
fi
