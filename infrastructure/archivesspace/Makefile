ifndef VERBOSE
.SILENT:
endif

ARCHIVESSPACE_API ?= http://localhost:8089

.PHONY: help start wait stop clean

help:
	@echo "make start      | start ArchivesSpace (first boot can take 10+ minutes)"
	@echo "make wait       | start ArchivesSpace and block until the API responds"
	@echo "make stop       | stop ArchivesSpace (data is preserved)"
	@echo "make clean      | stop ArchivesSpace and delete all data volumes"

start:
	docker compose up -d

wait: start
	@echo "Waiting for the ArchivesSpace API at $(ARCHIVESSPACE_API) (first boot can take 10+ minutes)..."
	@until curl -sf $(ARCHIVESSPACE_API) > /dev/null; do sleep 5; done
	@echo "ArchivesSpace API is ready. Staff UI: http://localhost:8080 (admin/admin)"

stop:
	docker compose down

clean:
	docker compose down -v
