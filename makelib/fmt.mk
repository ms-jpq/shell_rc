.PHONY: fmt systemd-fmt shfmt black prettier taplo luafmt

fmt: systemd-fmt shfmt black prettier taplo luafmt

systemd-fmt:
	./layers/posix/home/.local/bin/systemd-fmt.sh ./layers

shfmt: $(VAR)/bin/shfmt
	git ls-files --deduplicate -z -- '*.*sh' | grep -E -z -v -e '\.jsh$$' | xargs -r -0 -- '$<' --write --simplify --binary-next-line --space-redirects --indent 2 --

black: $(VENV)/$(PY_BIN)
	'$</isort' --profile=black --gitignore -- .
	'$</black' --extend-exclude pack -- .

prettier: ./node_modules/.bin
	'$</prettier' --cache --write -- .

taplo: ./node_modules/.bin
	git ls-files --deduplicate -z -- '*.toml' | xargs -r -0 -- '$</taplo' format --

luafmt: $(VAR)/bin/stylua
	git ls-files --deduplicate --stage -- '*.lua' | awk -- '$$1 !~ /^120000/ { print $$4 }' | tr -- '\n' '\0' | xargs -r -0 -n 1 -P 0 -- '$<' --
