EXTERNAL := sharp
C2PA_NODE_REPO := https://github.com/contentauth/c2pa-js
include ../lambda.mk

build-pyramidTiff: bundle
	TMPDIR=$$(mktemp -d) && \
	VERSION=$$(cat node_modules/@contentauth/c2pa-node/package.json | jq -r '.version') && \
	curl -Lso $${TMPDIR}/c2pa-node.zip $(C2PA_NODE_REPO)/releases/download/%40contentauth%2Fc2pa-node%40$${VERSION}/c2pa-node_x86_64-unknown-linux-gnu-v$${VERSION}.zip && \
	unzip -d $(ARTIFACTS_DIR) $${TMPDIR}/c2pa-node.zip