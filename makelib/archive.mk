.PHONY: s3 push pull

S5 := $(VAR)/bin/s5cmd$(OS_EXT)

push pull s3: | $(S5) ./node_modules/.bin
	./libexec/s3.sh '$@'
