#!/bin/bash

sam local start-lambda --warm-containers=LAZY --docker-network localstack_default -p 3006 \
  --parameter-overrides ParameterKey=S3Endpoint,ParameterValue=http://localstack:4566 ParameterKey=S3PathStyle,ParameterValue=true
