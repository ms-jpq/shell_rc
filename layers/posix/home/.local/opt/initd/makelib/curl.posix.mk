.PHONY: curl

$(TMP)/curl: | $(TMP)
	mkdir -v -p -- '$@'

GH_LATEST := ./libexec/gh-latest.sh $(TMP)/curl
