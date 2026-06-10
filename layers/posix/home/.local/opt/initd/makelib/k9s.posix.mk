.PHONY: k9s
all: k9s

K9S_SKIN := $(CONFIG)/k9s/skins/rose-pine-dawn.yaml

k9s: $(K9S_SKIN)
$(K9S_SKIN): | $(OPT)/k9s
	cp -v -f -- '$|/skins/rose-pine-dawn.yaml' '$@'
