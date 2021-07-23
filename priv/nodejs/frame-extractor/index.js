const AWS = require("aws-sdk");
const s3 = new AWS.S3();
const ffmpeg = require("fluent-ffmpeg");
const concat = require("concat-stream");
const URI = require("uri-js");
const M3U8FileParser = require("m3u8-file-parser");
const path = require("path");

AWS.config.update({ httpOptions: { timeout: 600000 } });

const handler = async (event, _context, _callback) => {
  if (event.source.endsWith(".m3u8")) {
    let source = event.source.replace(".m3u8", "-1080.m3u8");
    return await extractFrameFromPlaylist(
      source,
      event.destination,
      event.offset
    );
  } else {
    return await extractFrameFromVideo(
      event.source,
      event.destination,
      event.offset
    );
  }
};

const extractFrameFromPlaylist = async (source, destination, offset) => {
  return new Promise((resolve, reject) => {
    try {
      let uri = URI.parse(source);
      let key = getS3Key(uri);
      let off = offset;

      parsePlaylist(uri.host, key, off).then(
        ({ location, segmentOffset }) => {
          const segOffInSeconds = segmentOffset / 1000;

          let readStream = s3
            .getObject({ Bucket: uri.host, Key: location })
            .createReadStream()
            .on("error", (error) => console.error(error));

          let ffmpegProcess = new ffmpeg(readStream)
            .seek(segOffInSeconds)
            .outputOptions(["-vframes 1"])
            .toFormat("image2");

          const uploadStream = concat((data) => {
            const poster = URI.parse(destination);
            uploadToS3(data, poster.host, poster.path)
              .then((result) => resolve(result))
              .catch((err) => reject(err));
          });

          ffmpegProcess.pipe(uploadStream, { end: true });
        }
      );
    } catch (err) {
      reject(err);
    }
  });
};

const extractFrameFromVideo = async (source, destination, offset) => {
  return new Promise((resolve, reject) => {
    try {
      let uri = URI.parse(source);
      let key = getS3Key(uri);
      let readStream = s3
        .getObject({ Bucket: uri.host, Key: key })
        .createReadStream()
        .on("error", (error) => console.error(error));

      let ffmpegProcess = new ffmpeg(readStream)
        .seek(offset / 1000.0)
        .size("600x?")
        .outputOptions(["-vframes 1"])
        .toFormat("image2");

      const uploadStream = concat((data) => {
        const poster = URI.parse(destination);
        uploadToS3(data, poster.host, poster.path)
          .then((result) => resolve(result))
          .catch((err) => reject(err));
      });

      ffmpegProcess.pipe(uploadStream, { end: true });
    } catch (err) {
      reject(err);
    }
  });
};

const parsePlaylist = (bucket, key, offset) => {
  const reader = new M3U8FileParser();

  try {
    const readline = require("readline");
    let location = "";
    let segmentOffset = "";
    return new Promise((resolve, reject) => {
      let playlistStream = s3
        .getObject({ Bucket: bucket, Key: key })
        .createReadStream()
        .on("error", (error) => console.error(error));

      const interface = readline.createInterface({ input: playlistStream });
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

const uploadToS3 = (data, bucket, key) => {
  return new Promise((resolve, reject) => {
    s3.upload({ Bucket: bucket, Key: key, Body: data }, (err, _data) => {
      if (err) {
        reject(err);
      } else {
        resolve(`s3://${bucket}${key}`);
      }
    });
  });
};

const getS3Key = (uri) => {
  return uri.path.replace(/^\/+/, "");
};

module.exports = { handler };
