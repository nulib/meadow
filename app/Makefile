.PHONY: test

help:
	@echo "make all-deps          | fetch Elixir and front-end dependencies"
	@echo "make all-lint          | run JS and Elixir lint checks"
	@echo "make all-test          | run Elixir and JS tests"
	@echo "make compile           | compile Elixir code"
	@echo "make container         | build Meadow release container"
	@echo "make deps              | fetch Elixir dependencies"
	@echo "make frontend-build    | build front-end assets"
	@echo "make frontend-ci       | run front-end CI pipeline"
	@echo "make frontend-deps     | install front-end dependencies"
	@echo "make frontend-lint     | run JS lint checks"
	@echo "make frontend-list     | list front-end dependencies"
	@echo "make frontend-watch    | watch front-end assets for changes"
	@echo "make lint              | run Elixir lint checks"
	@echo "make livebook          | build Livebook+Meadow release container"
	@echo "make server            | run Phoenix server"
	@echo "make test              | run Elixir tests"

assets/node_modules/.install-stamp: assets/package.json assets/package-lock.json
	npm install --force --prefix assets
	@touch $@

deps/.install-stamp: mix.exs mix.lock
	mix deps.get
	@touch $@

frontend-deps: assets/node_modules/.install-stamp

frontend-build: frontend-deps
	npm run-script --prefix assets deploy
	
frontend-ci: frontend-deps frontend-list frontend-lint frontend-test frontend-build

frontend-list: frontend-deps
	npm list --prefix assets

frontend-watch: frontend-deps
	npm run --prefix assets watch

frontend-lint: frontend-deps
	npm run --prefix assets prettier

frontend-test: frontend-deps
	npm run-script --prefix assets ci:silent -- -w 1

deps: deps/.install-stamp

all-deps: deps frontend-deps

container: AWS_ACCOUNT_ID ?= $(shell aws sts get-caller-identity --query Account --output text)
container: AWS_REGION ?= us-east-1
container: CONTAINER_TAG ?= latest
container: ECR_REPO ?= $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com
container: RELEASE_NAME ?= meadow-$(shell git rev-parse --short HEAD)
container: BUILD_IMAGE ?= hexpm/elixir:1.18.2-erlang-27.3-debian-bookworm-20250224
container: RUNTIME_IMAGE ?= node:22-bookworm-slim
container: MEADOW_TENANT ?= meadow
container: MEADOW_VERSION ?= $(shell make version)
container:
	docker build \
		--build-arg HONEYBADGER_API_KEY=$(HONEYBADGER_API_KEY) \
		--build-arg HONEYBADGER_API_KEY_FRONTEND=$(HONEYBADGER_API_KEY_FRONTEND) \
		--build-arg HONEYBADGER_ENVIRONMENT=$(HONEYBADGER_ENVIRONMENT) \
		--build-arg HONEYBADGER_REVISION=$(HONEYBADGER_REVISION) \
		--build-arg BUILD_IMAGE=$(BUILD_IMAGE) \
		--build-arg RUNTIME_IMAGE=$(RUNTIME_IMAGE) \
		--build-arg MEADOW_TENANT=$(MEADOW_TENANT) \
		--build-arg MEADOW_VERSION=$(MEADOW_VERSION) \
		--tag $(ECR_REPO)/meadow:$(CONTAINER_TAG) \
		--tag $(ECR_REPO)/meadow:$(MEADOW_VERSION) \
		.

livebook: CONTAINER_TAG ?= latest
livebook: MEADOW_VERSION ?= $(shell make version)
livebook:
	docker build \
		--tag nulib/meadow:livebook-$(MEADOW_VERSION) \
		--tag nulib/meadow:livebook-$(CONTAINER_TAG) \
		-f ../Dockerfile.livebook \
		..

compile: deps
	mix compile

distclean: 
	rm -rf _build deps assets/node_modules

lint: deps
	mix credo

all-lint: lint frontend-lint

iex-server: deps frontend-deps
	iex -S mix phx.server

server: deps frontend-deps
	mix phx.server

test: deps
	AWS_LOCALSTACK=true \
	mix test $(ARGS) || \
		(test -z "$$MEADOW_TEST_SAVE_SEED" || mix test --seed $$(cat "$$MEADOW_TEST_SAVE_SEED") --failed $(ARGS))

all-test: test frontend-test

version:
	@awk -F'"' '/@app_version/ {print $$2; exit}' mix.exs
