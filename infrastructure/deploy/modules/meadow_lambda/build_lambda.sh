#!/bin/bash

set -e

eval "$(jq -r '@sh " NAME=\(.name) SOURCE_SHA=\(.source_sha) SOURCE_PATH=\(.source_path) DEST_PATH=\(.dest_path)"')"
DEST_ZIP="${DEST_PATH}/${NAME}-deploy-${SOURCE_SHA}.zip"
if [ ! -f $DEST_ZIP ]; then
  docker pull nulib/lambda-build >&2
  docker run -v ${PWD}/${SOURCE_PATH}:/src -v ${PWD}/${DEST_PATH}:/dest nulib/lambda-build ${NAME} ${SOURCE_SHA} >&2
fi
jq -n --arg zip "${DEST_ZIP}" '{"zip":$zip}'
