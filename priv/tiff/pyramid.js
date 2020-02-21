const AWS = require("aws-sdk");
const sharp = require("sharp");
const URI = require("uri-js");
const fs = require("fs");
const tempy = require("tempy");
const portlog = require("./portlog");

const createPyramidTiff = async (source, dest) => {
  const inputFile = await makeInputFile(source);
  try {
    portlog("info", `Creating pyramidal TIFF from ${inputFile}`)
    const pyramidTiff = await sharp(inputFile)
      .limitInputPixels(false)
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
  } finally {
    portlog("info", `Deleting ${inputFile}`)
    fs.unlink(inputFile, err => {
      if (err) { throw err; }
    });
  }
};

const makeInputFile = location => {
  return new Promise((resolve, reject) => {
    let uri = URI.parse(location);
    let fileName = tempy.file();
    portlog("info", `Retrieving ${location} to ${fileName}`);
    let writable = fs
      .createWriteStream(fileName)
      .on("error", err => reject(err));
    new AWS.S3()
      .getObject({
        Bucket: uri.host,
        Key: getS3Key(uri)
      })
      .createReadStream()
      .on("end", () => resolve(fileName))
      .on("error", err => reject(err))
      .pipe(writable);
  });
};

const sendToDestination = (data, location) => {
  portlog("info", `Writing to ${location}`);
  let uri = URI.parse(location);
  return new Promise((resolve, reject) => {
    new AWS.S3().upload(
      { Bucket: uri.host, Key: getS3Key(uri), Body: data },
      (err, _data) => {
        if (err) {
          reject(err);
        } else {
          resolve(location);
        }
      }
    );
  });
};

const getS3Key = uri => {
  return uri.path.replace(/^\/+/, "");
};

module.exports = { createPyramidTiff };
