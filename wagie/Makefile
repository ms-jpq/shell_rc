MAKEFLAGS += --check-symlink-times
MAKEFLAGS += --jobs
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --no-builtin-variables
MAKEFLAGS += --shuffle
MAKEFLAGS += --warn-undefined-variables
SHELL := bash
.DELETE_ON_ERROR:
.ONESHELL:
.SHELLFLAGS := --norc --noprofile -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar -c

.DEFAULT_GOAL := sync


REPO := https://github.com/ms-jpq/shell_rc
SRC := var/$(notdir $(REPO))

$(SRC):
	if [[ -d '$@' ]]; then
		git -C '$@' pull --rebase
	else
		git clone --recurse-submodules --shallow-submodules -- '$(REPO)' '$@'
	fi

sync: $(SRC)
	make --directory '$(SRC)' -- ant
	'$</wagie/link.sh' .
