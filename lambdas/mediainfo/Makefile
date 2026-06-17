build-mediainfo:
	find . -maxdepth 1 -type f ! -name 'Makefile' -exec cp {} "$(ARTIFACTS_DIR)/" \;
	bun install --cwd $(ARTIFACTS_DIR) --production --frozen-lockfile || \
	  bun install --cwd $(ARTIFACTS_DIR) --production
