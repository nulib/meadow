ifndef VERBOSE
.SILENT:
endif

MAKEFLAGS += --no-print-directory
SHELL := /bin/bash
LOCALSTACK_DIR ?= ./infrastructure/localstack
PIPELINE_DIR ?= ./infrastructure/pipeline
TERRAFORM_DIR ?= ./infrastructure/deploy

.PHONY: help

help:
	@make localstack-help | sed 's/^make /make localstack-/'
	@make pipeline-help   | sed 's/^make /make pipeline-/'

localstack-%: 
	cd $(LOCALSTACK_DIR) && make $*

pipeline-%:
	cd $(PIPELINE_DIR) && make $*

api-%:
	cd ../dc-api-v2 && make $*
