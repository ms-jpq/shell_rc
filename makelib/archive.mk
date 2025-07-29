.PHONY: s3 push pull

push pull s3: | $(VENV)/$(PY_BIN) ./node_modules/.bin
	./libexec/s3.sh '$@'
