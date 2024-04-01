.PHONY: git clobber.git

clobber: clobber.git

GIT_TMP := $(TMP)/git
GIT_DIRS :=

$(GIT_TMP):
	mkdir -v -p -- '$@'

define GIT_REPOS

$(GIT_TMP)/dircolors-solarized https://github.com/seebi/dircolors-solarized
$(GIT_TMP)/fzf                 https://github.com/junegunn/fzf
$(GIT_TMP)/z                   https://github.com/rupa/z

endef


define GIT_TEMPLATE

GIT_DIRS += $1
git: $1
$1: | $(GIT_TMP)
	if [[ -d '$$@' ]]; then
		git -C '$$@' pull --recurse-submodules --no-tags '--jobs=$(NPROC)'
	else
		git clone --recurse-submodules --shallow-submodules --depth=1 '--jobs=$(NPROC)' -- '$2' '$$@'
	fi

endef


GIT_REPOS := $(shell tr -s -- ' ' '!' <<<'$(GIT_REPOS)')

$(call META_2D,GIT_REPOS,GIT_TEMPLATE)
