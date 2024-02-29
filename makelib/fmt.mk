.PHONY: fmt systemd-fmt shfmt black prettier taplo

fmt: systemd-fmt shfmt black prettier taplo

systemd-fmt:
	export -- SYSTEMD_FMT_IGNORE
	SYSTEMD_FMT_IGNORE="$$(git ls-files -- '*/services/*.service')"
	./layers/posix/home/.local/bin/systemd-fmt.sh ./layers

shfmt: $(VAR)/bin/shfmt
	git ls-files --deduplicate -z -- '*.*sh' | xargs -r -0 -- '$<' --write --indent 2 --

black: ./.venv/bin
	'$</isort' --profile=black --gitignore -- .
	'$</black' --extend-exclude pack -- .

prettier: ./node_modules/.bin
	'$</prettier' --cache --write -- .

taplo: ./node_modules/.bin
	git ls-files --deduplicate -z -- '*.toml' | xargs -r -0 -- '$</taplo' format --
