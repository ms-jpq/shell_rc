.PHONY: lint mypy shellcheck hadolint tsc

lint: mypy shellcheck hadolint tsc

mypy: ./.venv/bin
	git ls-files --deduplicate -z -- '*.py' | xargs -r -0 -- '$</mypy' --

shellcheck: $(VAR)/bin/shellcheck
	git ls-files --deduplicate -z -- '*.*sh' | xargs -r -0 -- '$<' --

hadolint: $(VAR)/bin/hadolint
	git ls-files --deduplicate -z -- '*Dockerfile' | xargs -r -0 -- '$<' --

tsc: ./node_modules/.bin
	'$</tsc' --noEmit
