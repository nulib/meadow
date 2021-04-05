#!/bin/bash

curl \
  --data "deploy[environment]=${DEPLOY_TAG}&deploy[local_username]=&deploy[revision]=${CIRCLE_SHA1}&api_key=${HONEYBADGER_API_KEY}" \
  https://api.honeybadger.io/v1/deploys
