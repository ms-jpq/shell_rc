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

.PHONY: clobber sync git clobber.git

clobber: clobber.git

define META_2D
$(foreach line,$($1),$(eval $(call $2,$(firstword $(subst !, ,$(line))),$(lastword $(subst !, ,$(line))))))
endef

define GIT_TEMPLATE

.PHONY: clobber.git.$(notdir $1)
clobber.git: clobber.git.$(notdir $1)
clobber.git.$(notdir $1):
	rm -v -rf -- '$1'

git: $1
$1:
	if [[ -d '$$@' ]]; then
		git -C '$$@' pull --recurse-submodules --no-tags
	else
		git clone --recurse-submodules --shallow-submodules --depth=1 -- '$2' '$$@'
	fi

endef

define GIT_REPOS

var/shell_rc https://github.com/ms-jpq/shell_rc
var/ai       https://github.com/ms-jpq/ai
var/fzf      https://github.com/junegunn/fzf

endef

GIT_REPOS := $(shell tr -s -- ' ' '!' <<<'$(GIT_REPOS)')

$(call META_2D,GIT_REPOS,GIT_TEMPLATE)

sync: var/shell_rc | git
	make --directory '$<' -- ant
	cp -a -f -- '$</var/ant' ./
	'$</wagie/link.sh' .
