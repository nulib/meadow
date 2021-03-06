#!/bin/bash

container_id=$(docker create nulib/meadow:${DEPLOY_TAG})
docker cp ${container_id}:/app/lib/meadow-${MEADOW_VERSION}/priv/static/js ${container_id}
for source in app vendors~app; do
  js_file=$(ls ${container_id}/${source}.bundle-*.js)
  source_map=$(ls ${container_id}/${source}.js-*.map)
  curl https://api.honeybadger.io/v1/source_maps \
      -F api_key=${HONEYBADGER_API_KEY_FRONTEND} \
      -F revision=${CIRCLE_SHA1} \
      -F minified_url="https://meadow*.library.northwestern.edu/js/$(basename ${js_file})" \
      -F source_map=@${source_map} \
      -F minified_file=@${js_file}
done
