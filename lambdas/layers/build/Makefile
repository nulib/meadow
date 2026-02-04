LAYER_DIR ?= ..
TARGET_DIR ?= $(shell realpath $(LAYER_DIR))
MAKEFLAGS += -j4
.SILENT: 

$(LAYER_DIR)/exifToolLayer.zip:
	@echo "Building exifTool layer..."
	TMP_DIR=$$(mktemp -d) ; \
	DOCKER_IMAGE_ID_FILE=$$(mktemp) ; \
	VERSION=$$(curl -sL https://sourceforge.net/projects/exiftool/files/ver.txt/download); \
	docker buildx build -q --iidfile $$DOCKER_IMAGE_ID_FILE -f exiftool.dockerfile --build-arg EXIFTOOL_VERSION=$${VERSION} . ; \
	DOCKER_IMAGE_ID=$$(cat $$DOCKER_IMAGE_ID_FILE) ; \
	mkdir -p "$$TMP_DIR/bin" ; \
	docker run --rm $$DOCKER_IMAGE_ID | tar -C "$$TMP_DIR/bin" -x ; \
	(cd $$TMP_DIR && zip -r "$(TARGET_DIR)/exifToolLayer.zip" . >/dev/null) ; \
	rm $$DOCKER_IMAGE_ID_FILE; \
	rm -rf $$TMP_DIR

$(LAYER_DIR)/ffmpegLayer.zip:
	@echo "Building ffmpeg layer..."
	TMP_DIR=$$(mktemp -d) ; \
	mkdir -p "$$TMP_DIR/bin" ; \
	curl -sL https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz | tar -xJ --strip-components=1 -C "$$TMP_DIR/bin" ffmpeg-*/ffmpeg ffmpeg-*/ffprobe ; \
	(cd $$TMP_DIR && zip -r "$(TARGET_DIR)/ffmpegLayer.zip" . >/dev/null) ; \
	rm -rf $$TMP_DIR

$(LAYER_DIR)/mediaInfoLayer.zip:
	@echo "Building MediaInfo layer..."
	TMP_DIR=$$(mktemp -d) ; \
	VERSION=$$(curl -sL https://api.github.com/repos/MediaArea/MediaInfo/releases | jq -r '.[0].name'); \
	curl -sL -o "$(TARGET_DIR)/mediaInfoLayer.zip" https://mediaarea.net/download/binary/mediainfo/$${VERSION}/MediaInfo_CLI_$${VERSION}_Lambda_x86_64.zip ; \
	rm -rf $$TMP_DIR

$(LAYER_DIR)/perlLayer.zip:
	@echo "Building perl layer..."
	TMP_DIR=$$(mktemp -d) ; \
	DOCKER_IMAGE_ID_FILE=$$(mktemp) ; \
	VERSION=$$(curl -s 'https://fastapi.metacpan.org/v1/release/perl' | jq -r '.version' | awk '{printf "%.3f\n", $$1}' | sed 's/\./ /g' | awk '{printf "%d.%d.%d\n", $$1, $$2, $$3}'); \
	DOCKER_IMAGE_ID_FILE=$$(mktemp) ; \
	docker buildx build -q --iidfile $$DOCKER_IMAGE_ID_FILE -f perl.dockerfile --build-arg PERL_VERSION=$${VERSION} . ; \
	DOCKER_IMAGE_ID=$$(cat $$DOCKER_IMAGE_ID_FILE) ; \
	docker run --rm $$DOCKER_IMAGE_ID | tar -C "$$TMP_DIR" -x ; \
	(cd $$TMP_DIR && zip -r "$(TARGET_DIR)/perlLayer.zip" . >/dev/null) ; \
	rm $$DOCKER_IMAGE_ID_FILE; \
	rm -rf $$TMP_DIR

all: $(LAYER_DIR)/exifToolLayer.zip $(LAYER_DIR)/ffmpegLayer.zip $(LAYER_DIR)/mediaInfoLayer.zip $(LAYER_DIR)/perlLayer.zip
clean: 
	rm -f $(LAYER_DIR)/*.zip