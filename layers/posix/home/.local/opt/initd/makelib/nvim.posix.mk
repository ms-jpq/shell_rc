.PHONY: nvim

NVIM_MVP := $(CONFIG)/nvim/pack/modules/start/chadtree

nvim: $(NVIM_MVP)

$(NVIM_MVP): | $(CONFIG)/nvim
	env -- 'HOME=$(HOME)' 'USERPROFILE=$(HOME)' '$(GMAKE)' --directory '$(call UNIX_2_NT,$(CONFIG)/nvim)' -- mvp
