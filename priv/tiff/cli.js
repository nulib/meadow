#!/usr/bin/env node

const AWS = require("aws-sdk");
const pyramid = require("./pyramid");
const portlog = require("./portlog");

if (process.env["ECS_CONTAINER_METADATA_FILE"]) {
  var instanceMetadata = require(process.env["ECS_CONTAINER_METADATA_FILE"]);
  var awsRegion = instanceMetadata.ContainerInstanceARN.split(/:/)[3];
  AWS.config.update({ region: awsRegion });
}

if (process.env["AWS_S3_ENDPOINT"]) {
  AWS.config.s3 = {
    endpoint: process.env["AWS_S3_ENDPOINT"],
    s3ForcePathStyle: true
  };
}

process.stdin.resume();

process.stdin.on("data", data => {
  const { source, target } = JSON.parse(data);
  pyramid
    .createPyramidTiff(source, target)
    .then(_dest => {
      portlog("ok");
    }).catch(err => {
      portlog("fatal", err.message);
    });
});
process.stdin.on("end", () => {
  process.exit;
});

process.stdin.on("exit", () => {
  process.exit;
});
