#################### ########### ####################
#################### ASDF Region ####################
#################### ########### ####################

export ASDF_CONFIG_FILE="$XDG_CONFIG_HOME/asdfrc"
export ASDF_DATA_DIR="$XDG_DATA_HOME/asdf"

# INIT #
fpath=("$ASDF_DATA_DIR/completions" $fpath)
. "$ASDF_DATA_DIR/asdf.sh"
# INIT #
