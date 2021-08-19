#!/bin/bash

environment=$(echo $DEPLOY_ENV | tr a-z A-Z)
access_key_id_var=${environment}_AWS_ACCESS_KEY_ID
secret_key_var=${environment}_AWS_SECRET_ACCESS_KEY
echo "Configuring AWS default profile with ${access_key_id_var} and ${secret_key_var}"

aws configure set aws_access_key_id $(jq -r ".${access_key_id_var}" <<< $SECRETS)
aws configure set aws_secret_access_key $(jq -r ".${secret_key_var}" <<< $SECRETS)
aws configure set default.region us-east-1
