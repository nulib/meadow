const AWS = require("aws-sdk");
const s3 = new AWS.S3();
const ffmpeg = require("fluent-ffmpeg");
const concat = require("concat-stream");
const URI = require("uri-js");
const M3U8FileParser = require("m3u8-file-parser");
const path = require("path");

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
        let playlistStream = s3
          .getObject({ Bucket: uri.host, Key: key })
          .createReadStream()
          .on("error", (error) => console.error(error));

        parsePlaylist(playlistStream, offset, key).then(
          ({ location, segmentOffset }) => {
            console.log("location1: ", location);
            console.log("segmentOffset1: ", segmentOffset);

            offset = segmentOffset;

            readStream = s3
              .getObject({ Bucket: uri.host, Key: location })
              .createReadStream()
              .on("error", (error) => console.error(error));
          }
        );
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

const parsePlaylist = (input, offset, key) => {
  const reader = new M3U8FileParser();

  try {
    const readline = require("readline");
    let location = "";
    let segmentOffset = "";
    return new Promise((resolve, reject) => {
      const interface = readline.createInterface({ input: input });
      interface.on("line", (line) => {
        reader.read(line);
      });
      interface.on("close", () => {
        const result = reader.getResult();

        let elapsed = 0.0;
        for (segment of result.segments) {
          const duration = segment.inf.duration * 1000;

          if (elapsed + duration > offset) {
            location = path.parse(key).dir + "/" + segment.url;
            segmentOffset = offset - elapsed;
            console.log("location2: ", location);
            console.log("segmentOffset2: ", segmentOffset);
            break;
          }
          elapsed += duration;
        }
        resolve({ location: location, segmentOffset: segmentOffset });
      });
    });
  } finally {
    reader.reset();
  }
};

const getS3Key = (uri) => {
  return uri.path.replace(/^\/+/, "");
};

module.exports = { handler };
