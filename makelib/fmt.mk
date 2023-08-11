.PHONY: fmt shfmt black prettier taplo

fmt: shfmt black prettier taplo

shfmt: ./var/bin/shfmt
	readarray -t -d $$'\0' -- ARRAY < <(git ls-files --deduplicate -z -- '*.*sh')
	'$<' --write --indent 2 -- "$${ARRAY[@]}"

black: ./.venv/bin
	'$</isort' --profile=black --gitignore -- .
	'$</black' --extend-exclude pack -- .

prettier: ./node_modules/.bin
	'$</prettier' --cache --write -- .

taplo: ./node_modules/.bin
	readarray -t -d $$'\0' -- ARRAY < <(git ls-files --deduplicate -z -- '*.toml')
	'$</taplo' format -- "$${ARRAY[@]}"
