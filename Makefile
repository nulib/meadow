ifndef VERBOSE
.SILENT:
endif

SHELL := /bin/bash

SAM_PORT ?= 3005
SAM_HOST ?= 0.0.0.0
LAYER_BASE ?= s3://nul-public/lambda-layers
LAYER_DIR := .layers
LOCALSTACK_ENDPOINT ?= https://localhost.localstack.cloud:4566

.PHONY: help pipeline-layers pipeline-build pipeline-start pipeline-clean

help:
	echo "make localstack        | start localstack and apply terraform infrastructure"
	echo "make pipeline-layers   | download lambda layer zips for local SAM"
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

$(LAYER_DIR)/%.zip:
	mkdir -p lambdas/$(LAYER_DIR)
	aws s3 cp $(LAYER_BASE)/$*.zip lambdas/$(LAYER_DIR)/

pipeline-layers: $(LAYER_DIR)/exiftool_lambda_layer.zip $(LAYER_DIR)/ffmpeg.zip $(LAYER_DIR)/mediainfo_lambda_layer.zip $(LAYER_DIR)/lambda-layer-perl-5.30.zip

pipeline-build: pipeline-layers
	cd lambdas && sam build

pipeline-start: pipeline-layers node-deps
	cd lambdas && sam local start-lambda --host $(SAM_HOST) -p $(SAM_PORT) 

pipeline-clean:
	rm -rf .aws-sam $(LAYER_DIR) lambdas/*/node_modules
