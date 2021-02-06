const AWS = require("aws-sdk");
const crypto = require("crypto");

AWS.config.update({httpOptions: {timeout: 600000}});

const handler = async (event, context, _callback) => {
  return await generateDigest(event.bucket, event.key);
};

const generateDigest = (bucket, key) => {
  console.log(`Digesting s3://${bucket}/${key}`);
  return new Promise((resolve, reject) => {
    let sha256 = crypto.createHash("sha256");
    let sha1 = crypto.createHash("sha1");

    new AWS.S3()
      .getObject({ Bucket: bucket, Key: key })
      .on("httpData", (chunk) => {
        sha256.update(chunk);
        sha1.update(chunk);        
      })
      .on("httpDownloadProgress", ({loaded, total}) => {
        console.debug(`Processed ${loaded}/${total}`)
      })
      .on("httpDone", () => {
        resolve({ sha256: sha256.digest("hex"), sha1: sha1.digest("hex") });
      })
      .on("httpError", (err) => reject(err))
      .on("error", (err) => reject(err))
      .send();
  });
};

module.exports = { handler };
