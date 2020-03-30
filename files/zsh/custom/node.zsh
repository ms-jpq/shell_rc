#################### ########### ####################
#################### Node Region ####################
#################### ########### ####################

export NVM_DIR="$HOME/.nvm"
if [[ -s "/usr/local/opt/nvm/nvm.sh" ]]
then
  . "/usr/local/opt/nvm/nvm.sh"
fi

if [[ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ]]
then
  . "/usr/local/opt/nvm/etc/bash_completion.d/nvm"
fi


alias np='PATH="$PWD/node_modules/.bin:$PATH" '
# alias npx='export PATH="$PWD/node_modules/.bin:$PATH"'
