ifndef VERBOSE
.SILENT:
endif

SHELL := /bin/bash

SAM_PORT ?= 3005
SAM_HOST ?= 0.0.0.0
LAYER_DIR ?= lambdas/layers
LOCALSTACK_ENDPOINT ?= https://localhost.localstack.cloud:4566

.PHONY: help pipeline-layers pipeline-build pipeline-start pipeline-clean

env-check:
	@test -n "$(ENV)" || (echo "Error: ENV is required. Usage: make deploy ENV=production" && exit 1)
	@echo "Deploying to $(ENV)"

help:
	echo "make localstack        | start localstack and apply terraform infrastructure"
	echo "make pipeline-build    | build the SAM template for local lambdas"
	echo "make pipeline-start    | run sam local start-lambda on port $(SAM_PORT)"
	echo "make pipeline-clean    | remove SAM build artifacts and downloaded layers"

localstack:
	cd infrastructure/localstack && \
	docker compose up -d && \
	terraform apply -auto-approve -var-file test.tfvars -var localstack_endpoint=$(LOCALSTACK_ENDPOINT)

localstack-down:
	cd infrastructure/localstack && docker compose down -v

node-deps: lambdas/digester/node_modules lambdas/execute-fixity/node_modules lambdas/exif/node_modules 
node-deps: lambdas/frame-extractor/node_modules lambdas/mediainfo/node_modules lambdas/mime-type/node_modules 
node-deps: lambdas/pyramid-tiff/node_modules lambdas/stream-authorizer/node_modules

lambdas/%/node_modules:
	npm install --prefix lambdas/$*

pipeline-layers:
	cd lambdas/layers/build && make all

pipeline-build: pipeline-layers
	cd lambdas && SHARP_IGNORE_GLOBAL_LIBVIPS=1 sam build

pipeline-start: node-deps pipeline-layers
	cd lambdas && sam local start-lambda --warm-containers=LAZY --host $(SAM_HOST) -p $(SAM_PORT) 

pipeline-clean:
	cd lambdas && rm -rf .aws-sam */node_modules && \
	cd layers/build && make clean

pipeline-deploy: env-check pipeline-build
	cd lambdas && sam deploy --config-env $(ENV)
