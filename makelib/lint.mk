.PHONY: lint mypy shellcheck hadolint tsc lualint

lint: mypy shellcheck hadolint tsc lualint

mypy: $(VENV)/$(PY_BIN)
	git ls-files --deduplicate -z -- '*.py' | xargs -r -0 -- '$</mypy' --

shellcheck: $(VAR)/bin/shellcheck
	git ls-files --deduplicate -z -- '*.*sh' | grep -E -z -v -e '\.jsh$$' | xargs -r -0 -- '$<' --

hadolint: $(VAR)/bin/hadolint
	git ls-files --deduplicate -z -- '*Dockerfile' | xargs -r -0 -- '$<' --

tsc: ./node_modules/.bin
	'$</tsc' --noEmit

lualint: $(VAR)/opt/lua-language-server/bin/lua-language-server | $(TMP)
	mkdir -v -p -- '$(TMP)/luals'
	'$<' --check '$(CURDIR)' --configpath '$(CURDIR)/.luarc.json' --logpath '$(TMP)/luals' --checklevel Warning
