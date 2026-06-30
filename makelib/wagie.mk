.PHONY: wagie clobber.wagie

clobber: clobber.wagie

ifneq ($(OS),nt)
all: wagie
endif

WAGIE       := $(VAR)/wagie
COQ         := $(VAR)/coq_nvim
WAGIE_HOME  := ./layers/posix/home
WAGIE_NVIM  := $(WAGIE_HOME)/.config/nvim
WAGIE_RC    := $(foreach os,$(GOOS),$(TMP)/$(os)/rc/.config/zsh/.zshrc)

WAGIE_CONF  := $(shell find $(WAGIE_HOME)/.config -type f)
WAGIE_GEN   := $(WAGIE_HOME)/.config/kitty/conf.d/colours.conf $(WAGIE_HOME)/.config/ranger/rc.conf $(WAGIE_NVIM)/apriori/fmt.json $(WAGIE_NVIM)/apriori/lsp.json $(WAGIE_NVIM)/apriori/mappings.json

clobber.wagie:
	rm -vfr -- '$(WAGIE)' '$(COQ)'

$(COQ): | $(VAR)
	./libexec/git-sync.sh https://github.com/ms-jpq/coq_nvim '$@'

wagie: $(WAGIE)
$(WAGIE): ./wagie/compile.sh $(WAGIE_HOME)/.zshenv $(WAGIE_RC) $(WAGIE_CONF) $(WAGIE_GEN) | $(COQ)
	'$<' '$@' $(GOOS)
	cp -a -f -- '$(COQ)/lua/coq' '$(WAGIE)/config/nvim/lua/coq'
