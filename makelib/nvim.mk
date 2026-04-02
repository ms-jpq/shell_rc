.PHONY: nvim clobber.nvim

clobber: clobber.nvim
all: nvim

NVIM := ./layers/posix/home/.config/nvim

clobber.nvim:
	rm -vfr -- $(NVIM)/apriori/{lsp,fmt}.json

nvim: $(NVIM)/apriori/lsp.json
$(NVIM)/apriori/lsp.json: $(NVIM)/libexec/languages.sh $(NVIM)/lsp.yml | $(VENV)/$(PY_BIN)
	'$<' < '$(NVIM)/lsp.yml' > '$@'

nvim: $(NVIM)/apriori/fmt.json
$(NVIM)/apriori/fmt.json: $(NVIM)/libexec/language-map.jq $(NVIM)/language-map.json $(HELIX)/languages.json
	'$<' --slurpfile lmap '$(NVIM)/language-map.json' < '$(HELIX)/languages.json' > '$@'
