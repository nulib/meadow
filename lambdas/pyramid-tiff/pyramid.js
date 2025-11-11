const { S3ClientShim, GetObjectCommand, PutObjectCommand } = require("aws-s3-shim");
const concat = require("concat-stream");
const sharp = require("sharp");
const URI = require("uri-js");

const createPyramidTiff = (source, dest) => {
  return new Promise((resolve, reject) => {
    console.log(`Creating pyramid from ${source}`);
    streamFromS3(source)
    .then((inputStream) => {
      let metadata;
      const transformStream = sharp({
        limitInputPixels: false,
        sequentialRead: true,
        unlimited: true
      })
      .removeAlpha()
      .resize({
        width: 15000,
        height: 15000,
        fit: "inside",
        withoutEnlargement: true
      })
      .rotate()
      .tiff({
        compression: "jpeg",
        quality: 75,
        tile: true,
        tileHeight: 256,
        tileWidth: 256,
        pyramid: true
      })
      .withMetadata()
      .on("info", (info) => (metadata = info));

      const uploadStream = concat((data) => {
        console.log(`Saving to ${dest}`);
        uploadToS3(data, dest, metadata)
          .then((result) => resolve(result))
          .catch((err) => reject(err));
      });

      inputStream.pipe(transformStream).pipe(uploadStream);
    })
    .catch((err) => reject(err));
  });
};

const streamFromS3 = async (location) => {
  const uri = URI.parse(location);
  const s3Client = new S3ClientShim({ httpOptions: { timeout: 600000 } });
  const cmd = new GetObjectCommand({ Bucket: uri.host, Key: getS3Key(uri) });
  const { Body } = await s3Client.send(cmd);
  return Body;
};

const uploadToS3 = (data, location, { width, height }) => {
  let uri = URI.parse(location);
  return new Promise((resolve, reject) => {
    const s3Client = new S3ClientShim({ httpOptions: { timeout: 600000 } });
    const cmd = new PutObjectCommand({
      Bucket: uri.host,
      Key: getS3Key(uri),
      Body: data,
      Metadata: { width: width.toString(), height: height.toString() }
    });

    s3Client
      .send(cmd)
      .then((_data) => resolve(location))
      .catch((err) => reject(err));
  });
};

const getS3Key = (uri) => {
  return uri.path.replace(/^\/+/, "");
};

module.exports = { createPyramidTiff };
