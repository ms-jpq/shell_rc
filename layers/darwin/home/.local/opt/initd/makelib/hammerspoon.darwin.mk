.PHONY: hammerspoon

all: hammerspoon
hammerspoon: $(TP)/hammerspoon

$(TP)/hammerspoon: $(CONFIG)/hammerspoon/init.lua | $(TP)
	# hs -c 'hs.reload()'|| :
	touch -- '$@'
