.PHONY: nvim

nvim: | $(CONFIG)
	'$|/nvim/make.lua'
