const AWS = require("aws-sdk");
const s3 = new AWS.S3();
const ffmpeg = require("fluent-ffmpeg");
const concat = require("concat-stream");
const URI = require("uri-js");
const M3U8FileParser = require('m3u8-file-parser');

AWS.config.update({ httpOptions: { timeout: 600000 } });

const handler = async (event, _context, _callback) => {
  return await extractFrame(event.source, event.destination, event.offset);
};

const extractFrame = async (source, destination, offset) => {
  return new Promise((resolve, reject) => {
    try {
      let uri = URI.parse(source);
      const key = getS3Key(uri);

      let readStream = s3
        .getObject({ Bucket: uri.host, Key: key })
        .createReadStream()
        .on("error", (error) => console.error(error));

      if (key.endsWith(".m3u8")) {
        const reader = new M3U8FileParser();
        const readline = require('readline');
      
        const interface = readline.createInterface({ input: readStream });
        interface.on('line', line => {
          reader.read(line);
        });
        interface.on('close', () => {
          const result = reader.getResult();
          console.log("DURATION: ", result.targetDuration);
          console.log("SEGMENTS: ", result.segments.length);
          reader.reset();
        });
      }

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

const parsePlaylist = (input, offset) => {
};

const getS3Key = (uri) => {
  return uri.path.replace(/^\/+/, "");
};

module.exports = { handler };
