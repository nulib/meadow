#!/bin/bash

networkconfig=$(aws ecs describe-services --cluster ${ECS_CLUSTER} --service ${ECS_SERVICE} | jq -cM '.services[0].networkConfiguration')
overrides='{"containerOverrides":[{"name":"'${ECS_CONTAINER}'","environment": [{"name": "MEADOW_PROCESSES", "value": "none"}, {"name": "DB_POOL_SIZE", "value": "10"}],"command":["eval","Meadow.ReleaseTasks.migrate()"]}]}'
aws ecs run-task --platform-version 1.4.0 --cluster ${ECS_CLUSTER} --task-definition ${ECS_TASK} --overrides "${overrides}" --launch-type FARGATE --network-configuration ${networkconfig}
for service in $(aws ecs list-services --cluster meadow | jq -r '.serviceArns[] | split("/") | last'); do
  aws ecs update-service --cluster ${ECS_CLUSTER} --service ${service} --force-new-deployment
done
