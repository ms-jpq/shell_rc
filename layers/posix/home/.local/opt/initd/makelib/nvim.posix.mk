.PHONY: nvim

NVIM_MVP := $(CONFIG)/nvim/pack/modules/start/chadtree

nvim: $(NVIM_MVP)

$(NVIM_MVP): | $(CONFIG)/nvim
	gmake --directory '$(CONFIG)/nvim' -- mvp 'HOME=$(HOME)'
