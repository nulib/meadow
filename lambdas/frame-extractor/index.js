const AWS = require("aws-shim");
const s3 = new AWS.S3();
const ffmpeg = require("fluent-ffmpeg");
const concat = require("concat-stream");
const URI = require("uri-js");
const M3U8FileParser = require("m3u8-file-parser");
const path = require("path");

AWS.config.update({ httpOptions: { timeout: 600000 } });

const handler = async (event, _context, _callback) => {
  if (event.source.endsWith(".m3u8")) {
    return await extractFrameFromPlaylist(
      event.source,
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
    let uri = URI.parse(source);
    let key = getS3Key(uri);
    let off = offset;

    parsePlaylist(uri.host, key, off)
      .then(({ location, segmentOffset }) => {
        const segOffInSeconds = segmentOffset / 1000;

        let readStream = s3
          .getObject({ Bucket: uri.host, Key: location })
          .createReadStream()
          .on("error", (error) => console.error(error));

        let ffmpegProcess = new ffmpeg(readStream)
          .seek(segOffInSeconds)
          .outputOptions(["-vframes 1"])
          .toFormat("image2")
          .on("error", function (err, _stdout, _stderr) {
            console.error("Cannot process video: " + err.message);
          })
          .on("end", function (_stdout, _stderr) {
            console.log("Transcoding succeeded");
          });

        const uploadStream = concat((data) => {
          uploadToS3(data, destination)
            .then((result) => resolve(result))
            .catch((err) => reject(err));
        });

        ffmpegProcess.pipe(uploadStream, { end: true });
      })
      .catch((err) => {
        reject(err);
      });
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
        .outputOptions(["-vframes 1"])
        .toFormat("image2")
        .on("error", function (err, _stdout, _stderr) {
          console.error("Cannot process video: " + err.message);
        })
        .on("end", function (_stdout, _stderr) {
          console.log("Transcoding succeeded !");
        });

      const uploadStream = concat((data) => {
        uploadToS3(data, destination)
          .then((result) => resolve(result))
          .catch((err) => reject(err));
      });

      ffmpegProcess.pipe(uploadStream, { end: true });
    } catch (err) {
      reject(err);
    }
  });
};

const loadHighestQuality = async (bucket, key) => {
  const reader = new M3U8FileParser();
  try {
    const s3Response = await s3.getObject({ Bucket: bucket, Key: key }).promise();
    reader.read(s3Response.Body.toString('utf-8'));
    const playlist = reader.getResult();
    if (playlist.segments[0].url.match(/\.m3u8$/)) {
      const highSegment = playlist.segments.sort((a, b) => b.streamInf.bandwidth - a.streamInf.bandwidth)[0];
      const nextKey = path.join(path.dirname(key), highSegment.url);
      return await loadHighestQuality(bucket, nextKey);  
    }
    return { playlist, key };
  } finally {
    reader.reset();
  }
};

const parsePlaylist = async (bucket, key, offset) => {
  const source = await loadHighestQuality(bucket, key);

  let elapsed = 0.0;
  let segmentOffset = "";
  for (segment of source.playlist.segments) {
    const duration = segment.inf.duration * 1000;

    if (elapsed + duration > offset) {
      location = path.join(path.dirname(source.key), segment.url);
      segmentOffset = offset - elapsed;
      break;
    }
    elapsed += duration;
  }
  if (segmentOffset === "") {
    throw "Offset out of range";
  } else {
    return({ location: location, segmentOffset: segmentOffset });
  }
};

const uploadToS3 = (data, destination) => {
  const metadata = {
    "Content-type": "image",
  };
  return new Promise((resolve, reject) => {
    const poster = URI.parse(destination);
    s3.upload(
      {
        Bucket: poster.host,
        Key: getS3Key(poster),
        Body: data,
        Metadata: metadata,
      },
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

const getS3Key = (uri) => {
  return decodeURI(uri.path.replace(/^\/+/, ""));
};

module.exports = { handler };
