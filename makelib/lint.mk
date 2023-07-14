.PHONY: lint mypy shellcheck hadolint

lint: mypy shellcheck hadolint

mypy: ./.venv/bin
	'$</mypy' -- .

shellcheck: ./var/bin/shellcheck
	readarray -t -d $$'\0' -- ARRAY < <(git ls-files -z -- '*.*sh')
	'$<' -- "$${ARRAY[@]}"

hadolint: ./var/bin/hadolint
	readarray -t -d $$'\0' -- ARRAY < <(git ls-files -z -- '*Dockerfile')
	'$<' -- "$${ARRAY[@]}"
