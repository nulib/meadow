const s3 = require("@aws-sdk/client-s3");
const clientOpts =
  (process.env.AWS_S3_ENDPOINT && !process.env.AWS_DEV_ENVIRONMENT) ? 
    { endpoint: process.env.AWS_S3_ENDPOINT, forcePathStyle: true } : 
    {}

class S3ClientShim extends s3.S3Client {
  constructor(opts) {
    super({ ...clientOpts, ...opts });
  }
}
module.exports = { ...s3, S3ClientShim };
