ifndef VERBOSE
.SILENT:
endif

SHELL := /bin/bash

SAM_TEMPLATE ?= lambdas/template.local.yaml
SAM_PORT ?= 3005
SAM_HOST ?= 0.0.0.0
LAYER_BASE ?= s3://nul-public/lambda-layers
LAYER_DIR := lambdas/layers

.PHONY: help sam-layers sam-build sam-start sam-all sam-clean

help:
	echo "make sam-layers   | download lambda layer zips for local SAM"
	echo "make sam-build    | build the SAM template for local lambdas"
	echo "make sam-start    | run sam local start-lambda on port $(SAM_PORT)"
	echo "make sam-all      | sam-layers + sam-build + sam-start"
	echo "make sam-clean    | remove SAM build artifacts and downloaded layers"

sam-layers:
	mkdir -p $(LAYER_DIR)
	aws s3 cp $(LAYER_BASE)/exiftool_lambda_layer.zip $(LAYER_DIR)/
	aws s3 cp $(LAYER_BASE)/ffmpeg.zip $(LAYER_DIR)/
	aws s3 cp $(LAYER_BASE)/mediainfo_lambda_layer.zip $(LAYER_DIR)/
	aws s3 cp $(LAYER_BASE)/lambda-layer-perl-5.30.zip $(LAYER_DIR)/

sam-build:
	sam build -t $(SAM_TEMPLATE)

sam-start:
	sam local start-lambda --host $(SAM_HOST) -p $(SAM_PORT) -t $(SAM_TEMPLATE)

sam-all: sam-layers sam-build sam-start

sam-clean:
	rm -rf .aws-sam $(LAYER_DIR)
