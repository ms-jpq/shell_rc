#################### ############## ####################
#################### Command Region ####################
#################### ############## ####################

export FFF_OPENER="open_command"


#################### ############# ####################
#################### Unbind Region ####################
#################### ############# ####################

# used to be s, S
export FFF_KEY_LINK="off"
export FFF_KEY_LINK_ALL="off"

# used to be x
export FFF_KEY_EXECUTABLE="off"


#################### ############# ####################
#################### Hotkey Region ####################
#################### ############# ####################

export FFF_KEY_SHELL="!"
export FFF_KEY_GO_DIR=":"
export FFF_KEY_SEARCH="f"
export FFF_KEY_REFRESH="e"


export FFF_KEY_TO_TOP="["
export FFF_KEY_TO_BOTTOM="]"
export FFF_KEY_PREVIOUS="p"


export FFF_KEY_HIDDEN="."
export FFF_KEY_ATTRIBUTES="a"


export FFF_KEY_MKDIR="m"
export FFF_KEY_MKFILE="n"


#################### ########## ####################
#################### CUA Region ####################
#################### ########## ####################

# clear selec
export FFF_KEY_CLEAR="w"


# Rename
export FFF_KEY_RENAME="r"
export FFF_KEY_BULK_RENAME="b"
export FFF_KEY_BULK_RENAME_ALL="B"


# Yank is copy
export FFF_KEY_YANK="c"
export FFF_KEY_YANK_ALL="C"


# Move is cut
export FFF_KEY_MOVE="x"
export FFF_KEY_MOVE_ALL="X"


# Confirm Marked Actions
# will open editor
export FFF_KEY_PASTE="v"


# delete
export FFF_KEY_TRASH="d"
export FFF_KEY_TRASH_ALL="D"


#################### ############# ####################
#################### Trash Region ####################
#################### ############# ####################

# Do not use FFF's trash
export FFF_TRASH_CMD="trash"

export FFF_TRASH="$HOME"

export FFF_KEY_GO_TRASH="off"


#################### ################ ####################
#################### Bookmarks Region ####################
#################### ################ ####################

export FFF_KEY_GO_HOME="~"

export FFF_FAV1="/"
export FFF_FAV2=
export FFF_FAV3=
export FFF_FAV4=
export FFF_FAV5=
export FFF_FAV6=
export FFF_FAV7=
export FFF_FAV8=
export FFF_FAV9=


#################### ############## ####################
#################### Display Region ####################
#################### ############## ####################

export FFF_FILE_FORMAT=" %f"
export FFF_MARK_FORMAT=" >> %f*"


# Directory color [0-9]
export FFF_COL1=2

# Status color [0-9]
export FFF_COL2=7

# Selection color [0-9] (copied/moved files)
export FFF_COL3=6

# Cursor color [0-9]
export FFF_COL4=2


#################### ########### ####################
#################### NAVI Region ####################
#################### ########### ####################

fff() {
  local FFF_CD_FILE="$(mktemp)"
  FFF_CD_FILE="$FFF_CD_FILE" command fff "$@"
  cd "$(cat "$FFF_CD_FILE")" || return 1
}
