const AWS = require("aws-sdk");
const s3 = new AWS.S3();
const ffmpeg = require("fluent-ffmpeg");
const concat = require("concat-stream");
const URI = require("uri-js");

AWS.config.update({ httpOptions: { timeout: 600000 } });

const handler = async (event, _context, _callback) => {
  return await extractFrame(event.source, event.destination, event.offset);
};

const extractFrame = async (source, destination, offset) => {
  return new Promise((resolve, reject) => {
    try {
      let uri = URI.parse(source);
      console.log("S3 KEY:", getS3Key(uri));
      console.log("BUCKET:", uri.host);

      let readStream = s3
        .getObject({ Bucket: uri.host, Key: getS3Key(uri) })
        .createReadStream()
        .on("error", (error) => console.error(error));

      let ffmpegProcess = new ffmpeg(readStream)
        .outputOptions([`-vf select='eq(n,${offset - 1})'`, "-vframes 1"])
        .toFormat("image2");

      const uploadStream = concat((data) => {
        uploadToS3(data, destination)
          .then((result) => resolve(result))
          .catch((err) => reject(err));
      });

      const uploadToS3 = (data, destination) => {
        return new Promise((resolve, reject) => {
          let uri = URI.parse(destination);

          console.log("S3 KEY 2:", getS3Key(uri));
          console.log("BUCKET 2:", uri.host);

          s3.upload(
            { Bucket: uri.host, Key: getS3Key(uri), Body: data },
            (err, _data) => {
              if (err) {
                reject(err);
              } else {
                resolve(destination);
              }
            }
          );
        });
      };

      ffmpegProcess.pipe(uploadStream, { end: true });
    } catch (err) {
      reject(err);
    }
  });
};

const getS3Key = (uri) => {
  return uri.path.replace(/^\/+/, "");
};

module.exports = { handler };
