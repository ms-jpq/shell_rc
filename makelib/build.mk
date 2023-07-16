.PHONY: build build.ubuntu

build: build.ubuntu

build.ubuntu: ./docker/ubuntu.Dockerfile
	docker buildx build --progress plain --tag 'shell' --file '$<' -- .
