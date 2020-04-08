#################### ############## ####################
#################### Command Region ####################
#################### ############## ####################

export FFF_OPENER="open_command"

export FFF_TRASH_CMD="trash"
export FFF_TRASH="$HOME/.local/share/fff/trash"

export FFF_CD_FILE="$HOME/.fff_d"


#################### ############# ####################
#################### Unbind Region ####################
#################### ############# ####################

# Unbind VIM hotkeys
export FFF_KEY_CHILD1="off"
export FFF_KEY_PARENT1="off"
export FFF_KEY_SCROLL_DOWN1="off"
export FFF_KEY_SCROLL_UP1="off"


export FFF_KEY_LINK="off"
export FFF_KEY_LINK_ALL="off"


#################### ############# ####################
#################### Hotkey Region ####################
#################### ############# ####################

export FFF_KEY_SHELL="!"
export FFF_KEY_GO_DIR=":"
export FFF_KEY_SEARCH="f"
export FFF_KEY_REFRESH="e"


export FFF_KEY_TO_TOP="["
export FFF_KEY_TO_BOTTOM="]"
export FFF_KEY_PREVIOUS="-"


export FFF_KEY_HIDDEN="."
export FFF_KEY_ATTRIBUTES="a"


export FFF_KEY_CLEAR="l"
export FFF_KEY_RENAME="r"
export FFF_KEY_PASTE="v"


export FFF_KEY_MKDIR="m"
export FFF_KEY_MKFILE="n"


export FFF_KEY_YANK="x"
export FFF_KEY_YANK_ALL="X"


export FFF_KEY_MOVE="m"
export FFF_KEY_MOVE_ALL="M"


export FFF_KEY_TRASH="d"
export FFF_KEY_TRASH_ALL="D"


export FFF_KEY_BULK_RENAME="b"
export FFF_KEY_BULK_RENAME_ALL="B"


#################### ################ ####################
#################### Bookmarks Region ####################
#################### ################ ####################

export FFF_KEY_GO_HOME="~"
export FFF_KEY_GO_TRASH="t"


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

dc() {
  fff "$@"
  cd "$(cat "$FFF_CD_FILE")"
}
