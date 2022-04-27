UBUNTU_VERSION_TEST ?= latest
DOCKER ?= docker

.PHONY: test build/test

.DEFAULT_GOAL := test

build/test:
	$(DOCKER) build -t "tsuru/base-platform:$(UBUNTU_VERSION_TEST)" --build-arg ubuntu_version=$(UBUNTU_VERSION_TEST) .

test: build/test
	$(DOCKER) build --force-rm --pull=false --build-arg "image=tsuru/base-platform:$(UBUNTU_VERSION_TEST)" -t tsuru/base-platform:test test/
	$(DOCKER) run --rm -t -v $(shell pwd)/test:/tests tsuru/base-platform:test bats .
