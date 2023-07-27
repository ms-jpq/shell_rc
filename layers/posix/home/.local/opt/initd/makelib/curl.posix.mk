.PHONY: curl
all: curl

$(TMP)/curl: $(TMP)
	mkdir -p -- '$@'

GH_LATEST := ./libexec/gh-latest.sh $(TMP)/curl
