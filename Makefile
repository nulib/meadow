ifndef VERBOSE
.SILENT:
endif

SHELL := /bin/bash

SAM_TEMPLATE ?= lambdas/template.yaml
SAM_PORT ?= 3005
SAM_HOST ?= 0.0.0.0
LAYER_BASE ?= s3://nul-public/lambda-layers
LAYER_DIR := lambdas/.layers

.PHONY: help sam-layers sam-build sam-start sam-all sam-clean

help:
	echo "make sam-layers   | download lambda layer zips for local SAM"
	echo "make sam-build    | build the SAM template for local lambdas"
	echo "make sam-start    | run sam local start-lambda on port $(SAM_PORT)"
	echo "make sam-all      | sam-layers + sam-build + sam-start"
	echo "make sam-clean    | remove SAM build artifacts and downloaded layers"

$(LAYER_DIR)/%.zip:
	mkdir -p $(LAYER_DIR)
	aws s3 cp $(LAYER_BASE)/$*.zip $(LAYER_DIR)/

lambda-modules: lambdas/digester/node_modules lambdas/execute-fixity/node_modules lambdas/exif/node_modules 
lambda-modules: lambdas/frame-extractor/node_modules lambdas/mediainfo/node_modules lambdas/mime-type/node_modules 
lambda-modules: lambdas/pyramid-tiff/node_modules lambdas/stream-authorizer/node_modules

lambdas/%/node_modules:
	npm install --prefix lambdas/$*

sam-layers: $(LAYER_DIR)/exiftool_lambda_layer.zip $(LAYER_DIR)/ffmpeg.zip $(LAYER_DIR)/mediainfo_lambda_layer.zip $(LAYER_DIR)/lambda-layer-perl-5.30.zip

sam-build:
	sam build -t $(SAM_TEMPLATE)

sam-start: sam-layers lambda-modules
	sam local start-lambda --host $(SAM_HOST) -p $(SAM_PORT) -t $(SAM_TEMPLATE) --parameter-overrides LambdaLayerBase=.layers

sam-all: sam-layers sam-build sam-start

sam-clean:
	rm -rf .aws-sam $(LAYER_DIR) lambdas/*/node_modules
