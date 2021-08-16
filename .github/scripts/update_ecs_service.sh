#!/bin/bash

environment=$(echo $DEPLOY_ENV | tr a-z A-Z)
access_key_id_var=${environment}_AWS_ACCESS_KEY_ID
secret_key_var=${environment}_AWS_SECRET_ACCESS_KEY
AWS_ACCESS_KEY_ID="${!access_key_id_var}"
AWS_SECRET_ACCESS_KEY="${!secret_key_var}"

changed_files=$(git diff --name-only HEAD HEAD^)
case $changed_files in
  lib/meadow/indexing/*)
    reindex=true
    ;;
  priv/elasticsearch/*)
    reindex=true
    ;;
  *)
    reindex=false
    ;;
esac

networkconfig=$(aws ecs describe-services --cluster ${ECS_CLUSTER} --service ${ECS_SERVICE} | jq -cM '.services[0].networkConfiguration')
overrides='{"containerOverrides":[{"name":"'${ECS_CONTAINER}'","environment": [{"name": "MEADOW_PROCESSES", "value": "none"}, {"name": "DB_POOL_SIZE", "value": "10"}],"command":["eval","Meadow.ReleaseTasks.migrate('${reindex}')"]}]}'
aws ecs run-task --platform-version 1.4.0 --cluster ${ECS_CLUSTER} --task-definition ${ECS_TASK} --overrides "${overrides}" --launch-type FARGATE --network-configuration ${networkconfig}
for service in $(aws ecs list-services --cluster meadow | jq -r '.serviceArns[] | split("/") | last'); do
  aws ecs update-service --cluster ${ECS_CLUSTER} --service ${service} --force-new-deployment
done
