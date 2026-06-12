build-pyramidTiff:
	find . -maxdepth 1 -type f ! -name 'Makefile' -exec cp {} "$(ARTIFACTS_DIR)/" \;
	cd "$(ARTIFACTS_DIR)" && SHARP_IGNORE_GLOBAL_LIBVIPS=1 bun install --production --frozen-lockfile
