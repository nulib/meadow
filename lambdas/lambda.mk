EXTERNAL ?=

BUNDLE := $(ARTIFACTS_DIR)/index.mjs
NM     := $(ARTIFACTS_DIR)/node_modules

.PHONY: bundle build-%

bundle: $(BUNDLE) $(STAMPS)

$(BUNDLE): $(wildcard **/*.js) package.json bun.lock
	@mkdir -p $(ARTIFACTS_DIR)
	bun install --frozen-lockfile
	bun build index.js \
		--format=esm \
		--target=node \
		--sourcemap=linked \
		--outdir=$(ARTIFACTS_DIR) \
		--entry-naming=index.mjs \
		$(foreach pkg,$(EXTERNAL),--external=$(pkg))

build-%: bundle
	@: