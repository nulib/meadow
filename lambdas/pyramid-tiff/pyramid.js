const { S3Client, GetObjectCommand, PutObjectCommand } = require("@aws-sdk/client-s3");
const concat = require("concat-stream");
const sharp = require("sharp");

const MAX_DIMENSION = 15000;
const TILE_SIZE = 256;

const createPyramidTiff = (source, dest) => {
  return new Promise((resolve, reject) => {
    console.log(`Creating pyramid from ${source}`);
    streamFromS3(source)
    .then((inputStream) => {
      const transformStream = sharp({
        limitInputPixels: false,
        sequentialRead: true,
        unlimited: true
      })
      .removeAlpha()
      .resize({
        width: MAX_DIMENSION,
        height: MAX_DIMENSION,
        fit: "inside",
        withoutEnlargement: true
      })
      .rotate()
      .tiff({
        compression: "jpeg",
        quality: 75,
        tile: true,
        tileHeight: TILE_SIZE,
        tileWidth: TILE_SIZE,
        pyramid: true
      })
      .withMetadata();

      const uploadStream = concat((data) => {
        sharp(data)
          .metadata()
          .then((metadata) => {
            uploadToS3(data, dest, metadata)
              .then((result) => resolve(result));
          });
        console.log(`Saving to ${dest}`);
      });

      inputStream.pipe(transformStream).pipe(uploadStream);
    });
  });
};

const streamFromS3 = async (location) => {
  const s3Location = getS3Location(location);
  const s3Client = new S3Client(s3ClientOpts());
  const cmd = new GetObjectCommand(s3Location);
  const { Body } = await s3Client.send(cmd);
  return Body;
};

const uploadToS3 = (data, location, { width, height, pages }) => {
  const s3Location = getS3Location(location);
  return new Promise((resolve, reject) => {
    const s3Client = new S3Client(s3ClientOpts());
    const cmd = new PutObjectCommand({
      ...s3Location,
      Body: data,
      ContentType: "image/tiff",
      Metadata: {
        width: width.toString(),
        height: height.toString(),
        pages: pages.toString(),
        tilesize: TILE_SIZE.toString()
      }
    });

    s3Client
      .send(cmd)
      .then((_data) => resolve(location));
  });
};

const getS3Location = (location) => {
  const uri = new URL(location);
  const Bucket = uri.host;
  const Key = uri.pathname.slice(1);
  return { Bucket, Key };
};

const s3ClientOpts = () => {
  const forcePathStyle = process.env.AWS_S3_FORCE_PATH_STYLE === "true";
  const endpoint = process.env.AWS_S3_ENDPOINT;
  return { endpoint, forcePathStyle, httpOptions: { timeout: 600000 } };
};

module.exports = { createPyramidTiff };
