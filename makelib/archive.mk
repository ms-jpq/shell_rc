.PHONY: s3 push pull

S5 := $(VAR)/bin/s5cmd$(OS_EXT)

s3: | $(S5)
	./libexec/s3.sh

push pull: | $(S5)
	./libexec/s3.sh '$@'
