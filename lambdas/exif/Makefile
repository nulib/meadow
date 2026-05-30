build-exif:
	find . -maxdepth 1 -type f ! -name 'Makefile' -exec cp {} "$(ARTIFACTS_DIR)/" \;
	cd "$(ARTIFACTS_DIR)" && bun install --production --frozen-lockfile
