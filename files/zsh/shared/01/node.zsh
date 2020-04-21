#################### ############### ####################
#################### Node Env Region ####################
#################### ############### ####################

export PATH="$XDG_CONFIG_HOME/nodenv/bin:$PATH"
eval "$(nodenv init -)"


alias np='PATH="$PWD/node_modules/.bin:$PATH" '
alias npx='export PATH="$PWD/node_modules/.bin:$PATH"'
