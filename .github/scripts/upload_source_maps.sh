#!/bin/bash

docker pull $MEADOW_IMAGE
container_id=$(docker create ${MEADOW_IMAGE})
docker cp ${container_id}:/app/lib/meadow-${MEADOW_VERSION}/priv/static/js ${container_id}
cd $container_id
for minified_file in app*.js app*.css; do
  source_map=$(tail -1 $minified_file | sed -E 's/^.+sourceMappingURL=\W*(\S+).*$/\1/')
  for ext in "" ".gz"; do
    curl https://api.honeybadger.io/v1/source_maps \
        -F api_key=${HONEYBADGER_API_KEY_FRONTEND} \
        -F revision=${HONEYBADGER_REVISION} \
        -F minified_url="https://meadow*.library.northwestern.edu/js/$(basename ${minified_file}${ext})" \
        -F source_map=@${source_map}${ext} \
        -F minified_file=@${minified_file}${ext}
  done
done
