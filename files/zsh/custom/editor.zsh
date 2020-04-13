#################### ############# ####################
#################### Editor Region ####################
#################### ############# ####################

alias e='emacs'
alias v='nvim'


alias sc='shellcheck'

ec() {
  (
    echo '[*]'
    echo 'indent_size = 2'
    echo 'trim_trailing_whitespace = true'
    echo 'insert_final_newline = true'
  ) > ".editorconfig"
}


#################### ############ ####################
#################### Emacs Region ####################
#################### ############ ####################


alias et='sh -c "export EMACS_BENCHMARK=1; time emacs"'
