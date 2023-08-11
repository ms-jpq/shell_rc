.PHONY: lint mypy shellcheck hadolint

lint: mypy shellcheck hadolint

mypy: ./.venv/bin
	readarray -t -d $$'\0' -- ARRAY < <(git ls-files --deduplicate -z -- '*.py')
	'$</mypy' -- "$${ARRAY[@]}"

shellcheck: ./var/bin/shellcheck
	readarray -t -d $$'\0' -- ARRAY < <(git ls-files --deduplicate -z -- '*.*sh')
	'$<' -- "$${ARRAY[@]}"

hadolint: ./var/bin/hadolint
	readarray -t -d $$'\0' -- ARRAY < <(git ls-files --deduplicate -z -- '*Dockerfile')
	'$<' -- "$${ARRAY[@]}"
