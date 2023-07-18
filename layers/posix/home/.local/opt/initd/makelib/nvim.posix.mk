.PHONY: nvim

nvim: $(CONFIG)/nvim/pack/modules/start/chadtree

$(CONFIG)/nvim/pack/modules/start/chadtree: $(CONFIG)/nvim
	gmake --directory '$<' -- mvp
