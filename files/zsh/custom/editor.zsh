#################### ############ ####################
#################### Editor Region ####################
#################### ############ ####################

alias e='"$EDITOR"'

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

alias ee='emacsclient -t -a "$EDITOR"'

alias ep='touch .projectile'

alias et='sh -c "export EMACS_BENCHMARK=1; time emacs"'
