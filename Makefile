ifndef VERBOSE
.SILENT:
endif

MAKEFLAGS += --no-print-directory
SHELL := /bin/bash

LOCALSTACK_DIR ?= ./infrastructure/localstack
PIPELINE_DIR ?= ./infrastructure/pipeline
APP_DIR ?= ./app
ASSETS_DIR ?= $(APP_DIR)/assets

MIX ?= mix
NPM ?= npm
TEST_SERVICE_TIMEOUT ?= 120

.PHONY: \
	help \
	localstack-% \
	pipeline-% \
	version \
	deps \
	compile \
	assets-install \
	assets-build \
	assets-watch \
	lint-js \
	lint-elixir \
	lint \
	test-js \
	test-elixir \
	test-env-up \
	test-env-down \
	test-elixir-provision \
	test \
	check \
	build \
	setup \
	server \
	ci-js

help:
	@echo "make setup                 | install Elixir and JavaScript dependencies"
	@echo "make build                 | build frontend assets"
	@echo "make test                  | run JS tests + localstack-backed Elixir tests"
	@echo "make test-elixir-provision     | run Elixir tests with auto localstack setup/teardown"
	@echo "make test-elixir           | run Elixir tests only (expects env already set)"
	@echo "make lint                  | run JS and Elixir lint checks"
	@echo "make server                | run Phoenix server"
	@echo "make version               | print Meadow app version"
	@echo "make ci-js                 | run frontend CI pipeline"
	@make localstack-help | sed 's/^make /make localstack-/'
	@make pipeline-help   | sed 's/^make /make pipeline-/'

localstack-%:
	cd $(LOCALSTACK_DIR) && make $*

pipeline-%:
	cd $(PIPELINE_DIR) && make $*

version:
	@awk -F'"' '/@app_version/ {print $$2; exit}' $(APP_DIR)/mix.exs

deps:
	cd $(APP_DIR) && $(MIX) deps.get

compile:
	cd $(APP_DIR) && $(MIX) compile

assets-install:
	cd $(APP_DIR) && $(MIX) assets.install

assets-build:
	cd $(APP_DIR) && $(MIX) assets.build

assets-watch:
	cd $(ASSETS_DIR) && $(NPM) run watch

lint-js:
	cd $(ASSETS_DIR) && $(NPM) run-script prettier

lint-elixir:
	cd $(APP_DIR) && $(MIX) credo

lint: lint-js lint-elixir

test-js:
	cd $(ASSETS_DIR) && $(NPM) run-script ci:silent -- -w 1

test-elixir:
	cd $(APP_DIR) && ($(MIX) test || (test -n "$$MEADOW_TEST_SAVE_SEED" && $(MIX) test --seed $$(cat "$$MEADOW_TEST_SAVE_SEED") --failed))

test-env-up:
	$(MAKE) localstack-start
	cd $(LOCALSTACK_DIR) && timeout $(TEST_SERVICE_TIMEOUT) bash -c 'while ! ./all-healthy.sh; do sleep 2; done'
	$(MAKE) localstack-provision

test-env-down:
	$(MAKE) localstack-stop

test-elixir-provision:
	set -euo pipefail; \
	trap '$(MAKE) test-env-down' EXIT; \
	$(MAKE) test-env-up; \
	AWS_LOCALSTACK=true USE_SAM_LAMBDAS=true $(MAKE) test-elixir

test: test-js test-elixir-provision

check: lint test

build: assets-build

setup: deps assets-install

server:
	if [ ! -x "$(ASSETS_DIR)/node_modules/.bin/vite" ]; then \
		echo "Vite was not found. Installing frontend dependencies..."; \
		$(MAKE) assets-install; \
	fi
	cd $(APP_DIR) && $(MIX) phx.server

ci-js:
	cd $(ASSETS_DIR) && \
	$(NPM) ci --force --no-fund && \
	$(NPM) list && \
	$(NPM) run-script prettier && \
	$(NPM) run-script ci:silent -- -w 1 && \
	$(NPM) run-script deploy
