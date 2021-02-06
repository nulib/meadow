const AWS = require("aws-sdk");
const URI = require("uri-js");
const fs = require("fs");
const tempy = require("tempy");

AWS.config.update({httpOptions: {timeout: 600000}});

const getS3Key = uri => {
  return uri.path.replace(/^\/+/, "");
};

const cacheWorkingCopy = async (location) => {
  const filename = tempy.file();

  return new Promise((resolve, reject) => {
    let uri = URI.parse(location);
    let writable = fs
      .createWriteStream(filename)
      .on("error", err => reject(err));

    const errorHandler = (err) => {
      writable.end();
      fs.unlinkSync(filename);
      reject(err);
    }

    console.info(`Creating working copy of ${location} at ${filename}`);
    new AWS.S3()
      .getObject({Bucket: uri.host, Key: getS3Key(uri)})
      .on("httpData", (chunk) => {
        writable.write(chunk);
      })
      .on("httpDownloadProgress", ({loaded, total}) => {
        console.debug(`Retrieved ${loaded}/${total}`)
      })
      .on("httpDone", () => {
        writable.end();
        resolve(filename);
      })
      .on("httpError", errorHandler)
      .on("error", errorHandler)
      .send();
  });
}

module.exports = cacheWorkingCopy;