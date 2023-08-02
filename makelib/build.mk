.PHONY: build build.ubuntu

ifeq (x86_64-nt, $(MACHTYPE)-$(OS))
build: build.nt
else
build: build.ubuntu
endif

build.ubuntu: ./docker/ubuntu.Dockerfile
	docker buildx build --progress plain --tag 'shell' --file '$<' -- .

build.nt: ./docker/nt.Dockerfile
	docker build --tag 'shell' --file '$<' -- .
