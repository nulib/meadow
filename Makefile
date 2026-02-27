ifndef VERBOSE
.SILENT:
endif

MAKEFLAGS += --no-print-directory
SHELL := /bin/bash

APP_DIR ?= ./app
LOCALSTACK_DIR ?= ./infrastructure/localstack
PIPELINE_DIR ?= ./infrastructure/pipeline
MEADOW_VERSION ?= $(shell $(MAKE) --no-print-directory app-version)
IMAGE_TAG ?= latest
VERSIONS_FILE ?= livebook/versions
ELIXIR_VERSION ?= $(shell . $(VERSIONS_FILE) && echo $${elixir})
OTP_VERSION ?= $(shell . $(VERSIONS_FILE) && echo $${otp})
UBUNTU_VERSION ?= $(shell . $(VERSIONS_FILE) && echo $${ubuntu})
BUILD_IMAGE ?= hexpm/elixir:$(ELIXIR_VERSION)-erlang-$(OTP_VERSION)-ubuntu-$(UBUNTU_VERSION)
RUNTIME_IMAGE ?= ubuntu:$(UBUNTU_VERSION)

help:
	@make app-help | sed 's/^make /make app-/'
	@echo "make ci                    | install all dependencies, start test environment, and run all tests"
	@make localstack-help | sed 's/^make /make localstack-/'
	@make pipeline-help   | sed 's/^make /make pipeline-/'

$(VERSIONS_FILE):
	livebook_version=$$(curl -s https://api.github.com/repos/livebook-dev/livebook/releases | jq -r '[.[] | select(.tag_name != "nightly")][0].tag_name') && \
	curl -sL -o $@ "https://raw.githubusercontent.com/livebook-dev/livebook/refs/tags/$${livebook_version}/versions"

.tool-versions: $(VERSIONS_FILE)
	. $(VERSIONS_FILE) && \
	otp_major="$${otp%%.*}" && \
	sed -i "s/^erlang .*/erlang      $${otp}/" .tool-versions	&& \
	sed -i "s/^elixir .*/elixir      $${elixir}-otp-$${otp_major}/" .tool-versions

build-image: $(VERSIONS_FILE)
	@echo $(BUILD_IMAGE)

runtime-image: $(VERSIONS_FILE)
	@echo $(RUNTIME_IMAGE)

app-image: $(VERSIONS_FILE)
app-image: AWS_ACCOUNT_ID ?= $(shell aws sts get-caller-identity --query Account --output text)
app-image: AWS_REGION ?= us-east-1
app-image: ECR_REPO ?= $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com
app-image: RELEASE_NAME ?= meadow-$(shell git rev-parse --short HEAD)
app-image: NODE_VERSION ?= 22
app-image: MEADOW_TENANT ?= meadow
app-image:
	cd app && \
	docker build \
		--build-arg HONEYBADGER_API_KEY=$(HONEYBADGER_API_KEY) \
		--build-arg HONEYBADGER_API_KEY_FRONTEND=$(HONEYBADGER_API_KEY_FRONTEND) \
		--build-arg HONEYBADGER_ENVIRONMENT=$(HONEYBADGER_ENVIRONMENT) \
		--build-arg HONEYBADGER_REVISION=$(HONEYBADGER_REVISION) \
		--build-arg BUILD_IMAGE=$(BUILD_IMAGE) \
		--build-arg RUNTIME_IMAGE=$(RUNTIME_IMAGE) \
		--build-arg NODE_VERSION=$(NODE_VERSION) \
		--build-arg MEADOW_TENANT=$(MEADOW_TENANT) \
		--build-arg MEADOW_VERSION=$(MEADOW_VERSION) \
		--tag $(ECR_REPO)/meadow:$(IMAGE_TAG) \
		--tag $(ECR_REPO)/meadow:$(MEADOW_VERSION) \
		.

livebook-image:
	docker build \
		--tag nulib/meadow:livebook-$(MEADOW_VERSION) \
		--tag nulib/meadow:livebook-$(IMAGE_TAG) \
		-f Dockerfile.livebook \
		.

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