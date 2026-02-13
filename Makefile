ifndef VERBOSE
.SILENT:
endif

MAKEFLAGS += --no-print-directory
SHELL := /bin/bash

APP_DIR ?= ./app
LOCALSTACK_DIR ?= ./infrastructure/localstack
PIPELINE_DIR ?= ./infrastructure/pipeline

help:
	@make app-help | sed 's/^make /make app-/'
	@echo "make ci                    | install all dependencies, start test environment, and run all tests"
	@make localstack-help | sed 's/^make /make localstack-/'
	@make pipeline-help   | sed 's/^make /make pipeline-/'

localstack-%:
	cd $(LOCALSTACK_DIR) && make $*

pipeline-%:
	cd $(PIPELINE_DIR) && make $*

app-test: localstack-provision
app-all-test: localstack-provision

app-%:
	cd $(APP_DIR) && make $*

ci: localstack-provision app-all-deps app-all-test localstack-stop

clean: localstack-clean pipeline-clean

distclean: clean app-distclean