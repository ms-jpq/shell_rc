.PHONY: fmt systemd-fmt shfmt black prettier taplo

fmt: systemd-fmt shfmt black prettier taplo

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
