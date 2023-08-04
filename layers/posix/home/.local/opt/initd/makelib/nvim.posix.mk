.PHONY: nvim

NVIM_MVP := $(CONFIG)/nvim/pack/modules/start/chadtree

nvim: $(NVIM_MVP)

$(NVIM_MVP): | $(CONFIG)/nvim
	HOME='$(call UNESC_DRIVE,$(HOME))' gmake --directory '$(call UNESC_DRIVE,$(CONFIG)/nvim)' -- mvp
