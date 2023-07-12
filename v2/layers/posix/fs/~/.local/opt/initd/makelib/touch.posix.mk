.PHONY: touch

touch: $(HOME)/.ssh/config $(HOME)/.config/git/config $(HOME)/.cache/zz

$(HOME)/.ssh/config:
	touch -- '$@'

$(HOME)/.config/git/config:
	touch -- '$@'

$(HOME)/.cache/zz:
	touch -- '$@'
