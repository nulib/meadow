const AWS = require("aws-sdk");
const sharp = require("sharp");
const URI = require("uri-js");
const convert = require("color-convert");

const s3 = new AWS.S3();

AWS.config.update({ httpOptions: { timeout: 600000 } });

const handler = async (event, _context, _callback) => {
  return await extractDominantColor(event.source);
};

const extractDominantColor = async (location) => {
  console.log(`Extracting Dominant Color ${location}`);
  let s3Stream = streamFromS3(location);

  return new Promise((resolve, _reject) => {
    const pipeline = sharp();

    pipeline.stats().then((stats) => {
      const { dominant } = stats;

      [h, s, l] = convert.rgb.hsl(dominant["r"], dominant["g"], dominant["b"]);

      resolve({ h: h, s: s, l: l });
    });

    s3Stream.pipe(pipeline);
  });
};

const streamFromS3 = (location) => {
  let uri = URI.parse(location);
  console.log("uri", JSON.stringify(uri));
  return s3
    .getObject({ Bucket: uri.host, Key: getS3Key(uri) })
    .createReadStream();
};

const getS3Key = (uri) => {
  return uri.path.replace(/^\/+/, "");
};

module.exports = { handler };
