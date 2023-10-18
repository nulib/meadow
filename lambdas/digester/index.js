const { S3ClientShim, GetObjectCommand } = require("aws-s3-shim");
const crypto = require("crypto");

const handler = async (event, _context, _callback) => {
  return await generateDigest(event.bucket, event.key);
};

const generateDigest = (bucket, key) => {
  console.log(`Digesting s3://${bucket}/${key}`);
  return new Promise((resolve, reject) => {
    let sha256 = crypto.createHash("sha256");
    let sha1 = crypto.createHash("sha1");

    const s3Client = new S3ClientShim({ httpOptions: { timeout: 600000 } });
    s3Client
      .send(new GetObjectCommand({ Bucket: bucket, Key: key }))
      .then(({Body: s3Stream}) => {
        s3Stream
          .on("data", (chunk) => {
            sha256.update(chunk);
            sha1.update(chunk);
          })
          .on("end", () =>
            resolve({ sha256: sha256.digest("hex"), sha1: sha1.digest("hex") })
          )
          .on("error", (err) => reject(err));
      })
      .catch((err) => reject(err));
  });
};

module.exports = { handler };
