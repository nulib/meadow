#!/bin/bash

echo "Looking for index changes between ${GITHUB_SHA} and ${PRIOR_HEAD}"
changed_files=$(git diff --name-only ${GITHUB_SHA} ${PRIOR_HEAD})
case $changed_files in
  lib/meadow/indexing/*)
    reindex=true
    ;;
  priv/elasticsearch/*)
    reindex=true
    ;;
  config/releases.exs)
    reindex=true
    ;;
  *)
    reindex=false
    ;;
esac
echo "Reindex: ${reindex}"

networkconfig=$(aws ecs describe-services --cluster ${ECS_CLUSTER} --service ${ECS_SERVICE} | jq -cM '.services[0].networkConfiguration')
overrides='{"containerOverrides":[{"name":"'${ECS_CONTAINER}'","environment": [{"name": "MEADOW_PROCESSES", "value": "none"}, {"name": "DB_POOL_SIZE", "value": "10"}],"command":["eval","Meadow.ReleaseTasks.migrate('${reindex}')"]}]}'
aws ecs run-task --platform-version 1.4.0 --cluster ${ECS_CLUSTER} --task-definition ${ECS_TASK} --overrides "${overrides}" --launch-type FARGATE --network-configuration ${networkconfig}
for service in $(aws ecs list-services --cluster meadow | jq -r '.serviceArns[] | split("/") | last'); do
  aws ecs update-service --cluster ${ECS_CLUSTER} --service ${service} --force-new-deployment
done
