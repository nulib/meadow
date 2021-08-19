#!/bin/bash

curl \
  --data "deploy[environment]=${DEPLOY_ENV}&deploy[local_username]=Github+Actions&deploy[revision]=${HONEYBADGER_REVISION}&api_key=${HONEYBADGER_API_KEY}" \
  https://api.honeybadger.io/v1/deploys
