.PHONY: curl

$(TP)/curl: | $(TP)
	mkdir -v -p -- '$@'

GH_LATEST := ./libexec/gh-latest.sh $(TP)/curl
