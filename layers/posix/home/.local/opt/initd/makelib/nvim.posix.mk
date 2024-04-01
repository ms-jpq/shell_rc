.PHONY: nvim

NVIM_MVP := $(CONFIG)/nvim/pack/modules/start/chadtree

nvim: $(NVIM_MVP)

$(NVIM_MVP): | $(CONFIG)/nvim
	'$(MAKE)' --directory '$(call UNIX_2_NT,$(CONFIG)/nvim)' -- mvp 'USERPROFILE=$(HOME)'

