const AWS = require("aws-sdk");
const crypto = require("crypto");

AWS.config.update({
  httpOptions: {
    timeout: 600000
  }
});

const handler = async (event, _context, _callback) => {
  const record = event.Records[0].s3;
  const bucket = record.bucket.name;
  const key = record.object.key;
  const digests = await generateDigest(bucket, key);
  console.log("Digest result:", digests);
  const s3 = new AWS.S3();
  const tags = {
    TagSet: [{Key: "computed-md5", Value: digests.md5}, {Key: "computed-md5-last-modified", Value: Number(new Date()).toString()}]
  };
  const tagResult = await s3.putObjectTagging({
    Bucket: bucket,
    Key: key,
    Tagging: tags
  }).promise();
  console.log(tagResult);
  return tags;
};

const generateDigest = (bucket, key) => {
  console.log(`Digesting s3://${bucket}/${key}`);
  return new Promise((resolve, reject) => {
    let md5 = crypto.createHash("md5");

    let s3Stream = new AWS.S3()
      .getObject({
        Bucket: bucket,
        Key: key
      })
      .createReadStream();

    s3Stream
      .on("data", (chunk) => {
        md5.update(chunk);
      })
      .on("end", () =>
        resolve({
          md5: md5.digest("hex")
        })
      )
      .on("error", (err) => reject(err));
  });
};

module.exports = {
  handler
};