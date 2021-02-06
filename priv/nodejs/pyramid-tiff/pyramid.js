const AWS = require("aws-sdk");
const sharp = require("sharp");
const URI = require("uri-js");
const cacheWorkingCopy = require('./working-copy');
const fs = require('fs');

const createPyramidTiff = async (source, dest) => {
  const inputFile = await cacheWorkingCopy(source);
  try {
    console.info(`Creating pyramidal TIFF from ${inputFile}`);
    const pyramidTiff = await sharp(inputFile, { limitInputPixels: false })
      .resize({
        width: 15000,
        height: 15000,
        fit: "inside",
        withoutEnlargement: true
      })
      .tiff({
        compression: "jpeg",
        quality: 75,
        tile: true,
        tileHeight: 256,
        tileWidth: 256,
        pyramid: true
      })
      .toBuffer();
    await sendToDestination(pyramidTiff, dest);
    return dest;
  } finally {
    fs.unlinkSync(inputFile);
  }
};

const sendToDestination = (data, location) => {
  console.info(`Writing to ${location}`);
  let uri = URI.parse(location);
  return new Promise((resolve, reject) => {
    sharp(data).metadata().then(({width, height}) => {
      new AWS.S3().upload(
        { Bucket: uri.host, Key: getS3Key(uri), Body: data, Metadata: { width: width.toString(), height: height.toString() } },
        (err, _data) => {
          if (err) {
            reject(err);
          } else {
            resolve(location);
          }
        }
      );
    });
  });
};

const getS3Key = uri => {
  return uri.path.replace(/^\/+/, "");
};

module.exports = { createPyramidTiff };
