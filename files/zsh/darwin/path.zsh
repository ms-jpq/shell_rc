#################### ########### ####################
#################### Path Region ####################
#################### ########### ####################

PATHS=(
  "/usr/local/opt/bc/bin"
  "/usr/local/opt/coreutils/libexec/gnubin"
  "/usr/local/opt/curl/bin"
  "/usr/local/opt/findutils/libexec/gnubin"
  "/usr/local/opt/gnu-getopt/bin"
  "/usr/local/opt/gnu-sed/libexec/gnubin"
  "/usr/local/opt/gnu-tar/libexec/gnubin"
  "/usr/local/opt/gnu-which/libexec/gnubin"
  "/usr/local/opt/grep/libexec/gnubin"
  "/usr/local/opt/icu4c/bin"
  "/usr/local/opt/icu4c/sbin"
  "/usr/local/opt/lsof/bin"
  "/usr/local/opt/ncurses/bin"
  "/usr/local/opt/openssl/bin"
  "/usr/local/sbin"
)
pathprepend "${PATHS[@]}"
unset PATHS