.PHONY: nvim clobber.nvim

clobber: clobber.nvim
all: nvim

NVIM := ./layers/posix/home/.config/nvim

clobber.nvim:
	rm -vfr -- $(NVIM)/apriori/lsp.json

nvim: $(NVIM)/apriori/lsp.json
$(NVIM)/apriori/lsp.json: $(NVIM)/apriori/lsp.yml | $(VENV)/$(PY_BIN)
	'$(NVIM)/libexec/languages.sh' < '$<' > '$@'
