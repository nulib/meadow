const AWS = require("aws-sdk");
const Sharp = require("sharp");
const URI = require("uri-js");
const fs = require("fs");
const stream = require("stream");
const tempy = require("tempy");

function createPyramidTiff(source, dest) {
  return new Promise((resolve, reject) => {
    try {
      makeInputFile(source)
        .catch(err => reject(err))
        .then(inFile => {
          console.error(`Creating pyramidal TIFF from ${inFile}`);
          Sharp(inFile)
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
            .toBuffer()
            .then(data =>
              sendToDestination(data, dest)
                .then(resolve(dest))
                .catch(err => reject(err))
            )
            .finally(() => {
              console.error(`Deleting ${inFile}`);
              fs.unlink(inFile, err => {
                if (err) {
                  console.error(err);
                }
              });
            });
        });
    } catch (err) {
      reject(err);
    }
  });
}

function makeInputFile(location) {
  return new Promise((resolve, reject) => {
    var uri = URI.parse(location);
    if (uri.scheme == "s3") {
      var s3Key = uri.path.replace(/^\/+/, "");
      var fileName = tempy.file();
      console.error(`Retrieving ${location} to ${fileName}`);
      var writable = fs
        .createWriteStream(fileName)
        .on("error", err => reject(err));
      new AWS.S3()
        .getObject({
          Bucket: uri.host,
          Key: s3Key
        })
        .createReadStream()
        .on("end", () => resolve(fileName))
        .on("error", err => reject(err))
        .pipe(writable);
    } else {
      reject(`Unsupported input scheme: '${uri.scheme}'`);
    }
  });
}

function sendToDestination(data, location) {
  console.error(`Writing to ${location}`);
  return new Promise((resolve, reject) => {
    var uri = URI.parse(location);
    if (uri.scheme == "s3") {
      var s3Key = uri.path.replace(/^\/+/, "");
      new AWS.S3().upload(
        { Bucket: uri.host, Key: s3Key, Body: data },
        (err, _data) => {
          if (err) {
            reject(err);
          } else {
            resolve(location);
          }
        }
      );
    } else {
      throw `Unsupported output scheme: '${uri.scheme}'`;
    }
  });
}

module.exports = { createPyramidTiff };
