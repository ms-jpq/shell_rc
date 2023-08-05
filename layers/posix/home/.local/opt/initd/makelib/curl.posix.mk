.PHONY: curl

$(TP)/curl: | $(TP)
	mkdir -v -p -- '$@'

GH_LATEST := ./libexec/gh-latest.sh $(call NT_2_UNIX,$(TP)/curl)
