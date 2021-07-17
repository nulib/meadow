const AWS = require("aws-sdk");
const s3 = new AWS.S3();
const ffmpeg = require("fluent-ffmpeg");
const concat = require("concat-stream");

AWS.config.update({ httpOptions: { timeout: 600000 } });

const handler = async (event, _context, _callback) => {
  return await extractFrame(
    event.source,
    event.dest,
    event.key,
    event.offset
  );
};

const extractFrame = async (source, dest, key, offset) => {
  return new Promise((resolve, reject) => {
    try {
      let readStream = s3
        .getObject({ Bucket: source, Key: key })
        .createReadStream()
        .on("error", (error) => console.error(error));

      // const fs = require("fs");
      // let writeStream = fs.createWriteStream("/Users/brendan/frame.jpg");

      let ffmpegProcess = new ffmpeg(readStream)
        .outputOptions([`-vf select='eq(n,${offset - 1})'`, "-vframes 1"])
        .toFormat("image2");

      // ffmpegProcess.pipe(writeStream, { end: true });

      const uploadStream = concat((data) => {
        uploadToS3(data, dest, "frame.jpg")
          .then((result) => resolve(result))
          .catch((err) => reject(err));
      });

      const uploadToS3 = (data, bucket, key) => {
        return new Promise((resolve, reject) => {
          s3.upload({ Bucket: bucket, Key: key, Body: data }, (err, _data) => {
            if (err) {
              reject(err);
            } else {
              resolve(key);
            }
          });
        });
      };

      ffmpegProcess.pipe(uploadStream, {end: true});
    } catch(err) {
      reject(err);
    }
  });
};

module.exports = { handler };
