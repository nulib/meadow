const AWS = require("aws-sdk");
const exifr = require("exifr");
const URI = require("uri-js");
const fs = require("fs");
const tempy = require("tempy");

AWS.config.update({httpOptions: {timeout: 600000}});

const extractExif = async (source, options) => {
  const inputFile = await makeInputFile(source);

  try {
    console.log(`Extracting EXIF metadata from ${inputFile}`);

    const defaultOptions = {
      makerNote: false,
      pick: [
        "Artist",
        "BitsPerSample",
        "CellLength",
        "CellWidth",
        "ColorMap",
        "Compression",
        "Copyright",
        "DateTime",
        "ExtraSamples",
        "FillOrder",
        "FreeByteCounts",
        "FreeOffsets",
        "GrayResponseCurve",
        "GrayResponseUnit",
        "HostComputer",
        "ImageDescription",
        "ImageHeight",
        "ImageLength",
        "ImageWidth",
        "Make",
        "MaxSampleValue",
        "MinSampleValue",
        "Model",
        "NewSubfileType",
        "Orientation",
        "PhotometricInterpretation",
        "PlanarConfiguration",
        "ResolutionUnit",
        "SamplesPerPixel",
        "Software",
        "SubfileType",
        "Threshholding",
        "XResolution",
        "YResolution",
      ],
    };

    const forcedOptions = {
      jfif: true,
      icc: true,
      iptc: true,
      xmp: true,
      interop: true,
      chunkSize: 1024 * 1024,
    };

    options = Object.assign(options || defaultOptions, forcedOptions);
    const exif = await exifr.parse(inputFile, options);

    return exif;
  } finally {
    console.info(`Deleting ${inputFile}`);
    fs.unlink(inputFile, (err) => {
      if (err) {
        throw err;
      }
    });
  }
};

const makeInputFile = (location) => {
  return new Promise((resolve, reject) => {
    let uri = URI.parse(location);
    let fileName = tempy.file();
    console.info(`Retrieving ${location} to ${fileName}`);
    let writable = fs
      .createWriteStream(fileName)
      .on("error", (err) => reject(err));
    let s3Stream = new AWS.S3()
      .getObject({
        Bucket: uri.host,
        Key: getS3Key(uri),
      })
      .createReadStream();

    s3Stream.on("error", (err) => reject(err));
    s3Stream.on("data", (_chunk) => console.debug("ping"));

    s3Stream
      .pipe(writable)
      .on("close", () => resolve(fileName))
      .on("error", (err) => reject(err));
  });
};

const getS3Key = (uri) => {
  return uri.path.replace(/^\/+/, "");
};

module.exports = { extractExif };
