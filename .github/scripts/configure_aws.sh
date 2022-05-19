#!/bin/bash

environment=$(echo $DEPLOY_ENV | tr a-z A-Z)
access_key_id_var=${environment}_AWS_ACCESS_KEY_ID
access_key_id=$(jq -r ".${access_key_id_var}" <<< $SECRETS)
secret_key_var=${environment}_AWS_SECRET_ACCESS_KEY
secret_access_key=$(jq -r ".${secret_key_var}" <<< $SECRETS)

echo "Configuring AWS default profile with ${access_key_id_var} and ${secret_key_var}"
echo "AWS_ACCESS_KEY_ID=$access_key_id" >> $GITHUB_ENV
echo "AWS_SECRET_ACCESS_KEY=$secret_access_key" >> $GITHUB_ENV
echo "AWS_REGION=us-east-1" >> $GITHUB_ENV
