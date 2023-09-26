const AWS = require("aws-sdk");
if (process.env.AWS_S3_ENDPOINT && !process.env.AWS_DEV_ENVIRONMENT) {
  AWS.config.s3 = {
    endpoint: process.env.AWS_S3_ENDPOINT,
    s3ForcePathStyle: true
  };
}
module.exports = AWS;
