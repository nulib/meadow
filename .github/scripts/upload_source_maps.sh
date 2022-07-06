#!/bin/bash

docker pull $MEADOW_IMAGE
container_id=$(docker create ${MEADOW_IMAGE})
docker cp ${container_id}:/app/lib/meadow-${MEADOW_VERSION}/priv/static/js ${container_id}
for source in app vendors~app; do
  js_file=$(ls ${container_id}/${source}.bundle-*.js)
  source_map=$(ls ${container_id}/${source}.js-*.map)
  curl https://api.honeybadger.io/v1/source_maps \
      -F api_key=${HONEYBADGER_API_KEY_FRONTEND} \
      -F revision=${HONEYBADGER_REVISION} \
      -F minified_url="https://meadow*.library.northwestern.edu/js/$(basename ${js_file})" \
      -F source_map=@${source_map} \
      -F minified_file=@${js_file}
done
