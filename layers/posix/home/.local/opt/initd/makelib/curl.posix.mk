.PHONY: curl

$(TP)/curl: | $(TP)
	mkdir -v -p -- '$@'

GH_LATEST := ./libexec/gh-latest.sh '$(call UNIX_2_NT,$(TP)/curl)'
