LAMBDAS_DIR ?= ../../lambdas
SAM_PORT ?= 3005
SAM_HOST ?= 0.0.0.0
PIPELINE_LOG_DIR := $(shell mktemp -d)
PIPELINE_THREADS ?= 4

.PHONY: help layers build start clean

.aws-sam/build.toml: build

help:
	@echo "make build        | build the SAM template for deployment"
	@echo "make clean        | remove SAM build artifacts and downloaded layers"
	@echo "make deps         | install dependencies for all lambdas"
	@echo "make deploy       | deploy the pipeline stack to AWS"
	@echo "make layers       | build lambda layers"
	@echo "make start        | start the pipeline lambdas on port 3005 with live S3 service"

$(LAMBDAS_DIR)/%/node_modules/.install-stamp: $(LAMBDAS_DIR)/%/package.json $(LAMBDAS_DIR)/%/package-lock.json
	SHARP_IGNORE_GLOBAL_LIBVIPS=1 npm i --prefix $(LAMBDAS_DIR)/$*
	@touch $@

deps: $(LAMBDAS_DIR)/digester/node_modules/.install-stamp
deps: $(LAMBDAS_DIR)/execute-fixity/node_modules/.install-stamp
deps: $(LAMBDAS_DIR)/exif/node_modules/.install-stamp
deps: $(LAMBDAS_DIR)/frame-extractor/node_modules/.install-stamp
deps: $(LAMBDAS_DIR)/mediainfo/node_modules/.install-stamp
deps: $(LAMBDAS_DIR)/metadata-agent/node_modules/.install-stamp
deps: $(LAMBDAS_DIR)/mime-type/node_modules/.install-stamp
deps: $(LAMBDAS_DIR)/pyramid-tiff/node_modules/.install-stamp
deps: $(LAMBDAS_DIR)/stream-authorizer/node_modules/.install-stamp

env-check:
	@test -n "$(ENV)" || (echo "Error: ENV is required. Usage: make deploy ENV=production" && exit 1)
	@echo "Deploying to $(ENV)"

layers:
	cd layers/build && make all

build: layers
	sam build --use-container --cached

start: deps layers
	./start_multi.sh $(SAM_PORT) $(PIPELINE_THREADS)

clean:
	rm -rf .aws-sam $(LAMBDAS_DIR)/*/node_modules && \
	cd layers/build && make clean

deploy: env-check .aws-sam/build.toml
	sam deploy --config-env $(ENV)
