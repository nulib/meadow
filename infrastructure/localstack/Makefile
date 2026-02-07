LOCALSTACK_ENDPOINT ?= https://localhost.localstack.cloud:4566

.PHONY: start provision stop

help:
	@echo "make start      | start localstack and apply terraform infrastructure"
	@echo "make provision  | apply terraform infrastructure"
	@echo "make stop       | stop localstack and remove volumes"

start:
	@cd ../pipeline && make deps layers
	docker compose up -d

provision: start
	@terraform init
	terraform apply -auto-approve -var-file test.tfvars -var localstack_endpoint=$(LOCALSTACK_ENDPOINT)

stop:
	@docker ps -aq --filter "label=sam.cli.container.type" | xargs -r docker rm -f > /dev/null
	docker compose down -v
