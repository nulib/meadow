#!/bin/bash

compose_dir=$(dirname "$0")
docker compose -f $compose_dir/docker-compose.yml ps
statuses=$(docker compose -f $compose_dir/docker-compose.yml ps -q | xargs docker inspect --format='{{.State.Health.Status}}' 2>/dev/null)
if [[ $(echo -n $statuses | wc -w) -lt 3 ]] || (echo $statuses | grep "starting\|unhealthy" > /dev/null); then
  docker compose -f $compose_dir/docker-compose.yml logs --tail=30
  echo "One or more services are not healthy"
  exit 1
else
  echo "All services are healthy"
  exit 0
fi
