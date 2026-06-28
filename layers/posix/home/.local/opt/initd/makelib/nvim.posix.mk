.PHONY: nvim

nvim: | $(CONFIG)
	'$|/nvim/libexec/make.lua'
