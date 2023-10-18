const { S3ClientShim, GetObjectCommand, PutObjectCommand } = require("aws-s3-shim");
const ffmpeg = require("fluent-ffmpeg");
const concat = require("concat-stream");
const URI = require("uri-js");
const M3U8FileParser = require("m3u8-file-parser");
const path = require("path");

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

const streamToString = (stream) =>
  new Promise((resolve, reject) => {
    const chunks = [];
    stream.on("data", (chunk) => chunks.push(chunk));
    stream.on("error", reject);
    stream.on("end", () => resolve(Buffer.concat(chunks).toString("utf8")));
  });

const extractFrameFromPlaylist = async (source, destination, offset) => {
  return new Promise((resolve, reject) => {
    let uri = URI.parse(source);
    let key = getS3Key(uri);
    let off = offset;

    parsePlaylist(uri.host, key, off)
      .then(({ location, segmentOffset }) => {
        const segOffInSeconds = segmentOffset / 1000;

        const s3Client = new S3ClientShim({ httpOptions: { timeout: 600000 } });
        s3Client
          .send(new GetObjectCommand({ Bucket: uri.host, Key: location }))
          .then(({ Body: readStream }) => {
            readStream.on("error", (error) => console.error(error));

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
        .catch((err) => reject(err));
      })
      .catch((err) => reject(err));
  });
};

const extractFrameFromVideo = async (source, destination, offset) => {
  let uri = URI.parse(source);
  let key = getS3Key(uri);

  const s3Client = new S3ClientShim({ httpOptions: { timeout: 600000 } });
  const { Body: readStream } = await s3Client.send(new GetObjectCommand({ Bucket: uri.host, Key: key }));
  readStream.on("error", (error) => console.error(error));

  return new Promise((resolve, reject) => {
    try {
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
    const s3Client = new S3ClientShim({ httpOptions: { timeout: 600000 } });
    const { Body } = await s3Client.send(new GetObjectCommand({ Bucket: bucket, Key: key }));
    const m3u8 = await streamToString(Body);
    reader.read(m3u8);
    const playlist = reader.getResult();
    if (playlist.segments[0].url.match(/\.m3u8$/)) {
      const highSegment = playlist.segments.sort(
        (a, b) => b.streamInf.bandwidth - a.streamInf.bandwidth
      )[0];
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
    return { location: location, segmentOffset: segmentOffset };
  }
};

const uploadToS3 = (data, destination) => {
  const metadata = {
    "Content-Type": "image"
  };
  return new Promise((resolve, reject) => {
    const poster = URI.parse(destination);
    const s3Client = new S3ClientShim({ httpOptions: { timeout: 600000 } });
    const cmd = new PutObjectCommand({
      Bucket: poster.host,
      Key: getS3Key(poster),
      Body: data,
      Metadata: metadata
    });
    s3Client
      .send(cmd)
      .then((_data) => resolve(destination))
      .catch((err) => reject(err));
  });
};

const getS3Key = (uri) => {
  return decodeURI(uri.path.replace(/^\/+/, ""));
};

module.exports = { handler };
