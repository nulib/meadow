const AWS = require("aws-shim");
const crypto = require("crypto");

AWS.config.update({httpOptions: {timeout: 600000}});

const handler = async (event, _context, _callback) => {
  return await generateDigest(event.bucket, event.key);
};

const generateDigest = (bucket, key) => {
  console.log(`Digesting s3://${bucket}/${key}`);
  return new Promise((resolve, reject) => {
    let sha256 = crypto.createHash("sha256");
    let sha1 = crypto.createHash("sha1");

    let s3Stream = new AWS.S3()
      .getObject({ Bucket: bucket, Key: key })
      .createReadStream();

    s3Stream
      .on("data", (chunk) => {
        sha256.update(chunk);
        sha1.update(chunk);
      })
      .on("end", () =>
        resolve({ sha256: sha256.digest("hex"), sha1: sha1.digest("hex") })
      )
      .on("error", (err) => reject(err));
  });
};

module.exports = { handler };
