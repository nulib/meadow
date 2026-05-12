LOCALSTACK_ENDPOINT ?= https://localhost.localstack.cloud:4566

.PHONY: start provision stop

terraform.tfstate: .localstack/.start-stamp test.tfvars
	@terraform init
	terraform apply -auto-approve -var-file test.tfvars -var localstack_endpoint=$(LOCALSTACK_ENDPOINT)
	@touch $@

.localstack/.start-stamp: docker-compose.yml
	@if [[ -z "$$LOCALSTACK_AUTH_TOKEN" ]]; then \
		echo "⚠️ IMPORTANT"; \
		echo "LocalStack authentication token not found. Please go to https://app.localstack.cloud/settings/auth-tokens to retrieve your Personal Auth Token and add \`export LOCALSTACK_AUTH_TOKEN=<your_token>\` to your shell initialization script." >&2; \
		exit 1; \
	fi
	(cd ../pipeline && $(MAKE) deps layers)
	docker compose up -d

help:
	@echo "make start      | start localstack"
	@echo "make provision  | apply terraform infrastructure"
	@echo "make stop       | stop localstack and remove volumes"

start: .localstack/.start-stamp

provision: terraform.tfstate

stop:
	@docker ps -aq --filter "label=sam.cli.container.type" | xargs -r docker rm -f > /dev/null
	docker compose down -v

clean: stop
	rm -rf .localstack .terraform terraform.tfstate* *.plan