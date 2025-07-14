.PHONY: s3 push pull

push pull s3: | $(VENV)/bin ./node_modules/.bin
	./libexec/s3.sh '$@'
