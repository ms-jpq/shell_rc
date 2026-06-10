.PHONY: ant clobber.ant

clobber: clobber.ant

ifneq ($(OS),nt)
all: ant
endif

ANT       := $(VAR)/ant
ANT_HOME  := ./layers/posix/home
ANT_NVIM  := $(ANT_HOME)/.config/nvim
ANT_RC    := $(foreach os,$(GOOS),$(TMP)/$(os)/rc/.config/zsh/.zshrc)

ANT_CONF  := $(shell find $(ANT_HOME)/.config -type f)
ANT_GEN   := $(ANT_HOME)/.config/kitty/conf.d/colours.conf $(ANT_NVIM)/apriori/lsp.json $(ANT_NVIM)/apriori/fmt.json

clobber.ant:
	rm -vfr -- '$(ANT)'

ant: $(ANT)
$(ANT): ./wagie/compile.sh $(ANT_HOME)/.zshenv $(ANT_RC) $(ANT_CONF) $(ANT_GEN)
	'$<' '$@' $(GOOS)
