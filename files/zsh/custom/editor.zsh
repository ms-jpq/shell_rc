#################### ############# ####################
#################### Editor Region ####################
#################### ############# ####################

alias sc='shellcheck'

ec() {
  (
    echo '[*]'
    echo 'indent_size = 2'
    echo 'insert_final_newline = true'
  ) > ".editorconfig"
}


#################### ############ ####################
#################### Emacs Region ####################
#################### ############ ####################

alias e='emacs'
alias ee='TERM=screen-256color emacs'

alias et='sh -c "export EMACS_BENCHMARK=1; time emacs"'


#################### ########## ####################
#################### Vim Region ####################
#################### ########## ####################

alias v='nvim'
alias vi='nvim'
alias vim='nvim'
