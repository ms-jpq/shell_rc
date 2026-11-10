.PHONY: fzf.posix

zsh: fzf.posix

FZF_INTEGRATIONS := $(CACHE)/fzf/integration.bash $(CACHE)/fzf/integration.zsh
FZF_BINARY :=

ifeq ($(OS),darwin)
FZF_BINARY := $(BREW_PREFIX)/bin/fzf
else ifeq ($(OS),linux)
FZF_BINARY := /usr/bin/fzf
endif

fzf.posix: $(FZF_INTEGRATIONS)
$(FZF_BINARY) $(FZF_INTEGRATIONS): | pkg.posix

$(CACHE)/fzf:
	mkdir -v -p -- '$@'

$(FZF_INTEGRATIONS): $(CACHE)/fzf/integration.%: $(FZF_BINARY) | $(CACHE)/fzf
	fzf '--$*' > '$@'
