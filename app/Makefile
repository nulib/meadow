.PHONY: test

help:
	@echo "make all-deps          | fetch Elixir and front-end dependencies"
	@echo "make all-lint          | run JS and Elixir lint checks"
	@echo "make all-test          | run Elixir and JS tests"
	@echo "make compile           | compile Elixir code"
	@echo "make container         | build Meadow release container"
	@echo "make deps              | fetch Elixir dependencies"
	@echo "make frontend-build    | build front-end assets"
	@echo "make frontend-ci       | run front-end CI pipeline"
	@echo "make frontend-deps     | install front-end dependencies"
	@echo "make frontend-lint     | run JS lint checks"
	@echo "make frontend-list     | list front-end dependencies"
	@echo "make frontend-watch    | watch front-end assets for changes"
	@echo "make lint              | run Elixir lint checks"
	@echo "make livebook          | build Livebook+Meadow release container"
	@echo "make server            | run Phoenix server"
	@echo "make test              | run Elixir tests"

assets/node_modules/.install-stamp: assets/package.json assets/package-lock.json
	npm install --force --prefix assets
	@touch $@

deps/.install-stamp: mix.exs mix.lock
	mix deps.get
	@touch $@

frontend-deps: assets/node_modules/.install-stamp

frontend-build: frontend-deps
	npm run-script --prefix assets deploy
	
frontend-ci: frontend-deps frontend-list frontend-lint frontend-test frontend-build

frontend-list: frontend-deps
	npm list --prefix assets

frontend-watch: frontend-deps
	npm run --prefix assets watch

frontend-lint: frontend-deps
	npm run --prefix assets prettier

frontend-test: frontend-deps
	npm run-script --prefix assets ci:silent -- -w 1

deps: deps/.install-stamp

all-deps: deps frontend-deps

images:
	@echo "Livebook versions: $(LIVEBOOK_VERSIONS)"
	@echo "Build image: $(BUILD_IMAGE)"
	@echo "Runtime image: $(RUNTIME_IMAGE)"

compile: deps
	mix compile

distclean: 
	rm -rf _build deps assets/node_modules

lint: deps
	mix credo

all-lint: lint frontend-lint

iex-server: deps frontend-deps
	iex -S mix phx.server

server: deps frontend-deps
	mix phx.server

test: deps
	AWS_LOCALSTACK=true \
	mix test $(ARGS) || \
		(test -z "$$MEADOW_TEST_SAVE_SEED" || mix test --seed $$(cat "$$MEADOW_TEST_SAVE_SEED") --failed $(ARGS))

all-test: test frontend-test

version:
	@awk -F'"' '/@app_version/ {print $$2; exit}' mix.exs
