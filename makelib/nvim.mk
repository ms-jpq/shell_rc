.PHONY: nvim clobber.nvim

clobber: clobber.nvim
all: nvim

NVIM := ./layers/posix/home/.config/nvim

clobber.nvim:
	rm -vfr -- $(NVIM)/apriori/{lsp,fmt}.json

nvim: $(NVIM)/apriori/lsp.json
$(NVIM)/apriori/lsp.json: $(NVIM)/libexec/languages.sh $(NVIM)/apriori/lsp.yml | $(VENV)/$(PY_BIN)
	'$<' < '$(NVIM)/apriori/lsp.yml' > '$@'

nvim: $(NVIM)/apriori/fmt.json
$(NVIM)/apriori/fmt.json: $(NVIM)/libexec/language-map.jq $(HELIX)/languages.json | $(VENV)/$(PY_BIN)
	'$<' < '$(HELIX)/languages.json' > '$@'

