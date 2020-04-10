#################### ############ ####################
#################### Editor Region ####################
#################### ############ ####################

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

alias e='emacs'
alias ee='emacsclient -t -a emacs'

alias ep='touch .projectile'

alias et='time EMACS_BENCHMARK=1 e'
