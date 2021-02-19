const AWS = require("aws-sdk");
const exifr = require("exifr");
const URI = require("uri-js");

AWS.config.update({httpOptions: {timeout: 600000}});

const extractExif = (source, options) => {
  return new Promise((resolve, reject) => {
    const s3 = new AWS.S3();
    const uri = URI.parse(source);

    console.log(`Retrieving ${source}`);

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
    
    s3.getObject({ Bucket: uri.host, Key: getS3Key(uri) }, (error, response) => {
      if(error) {
        reject(error)
      } else {
        console.log(`Extracting EXIF metadata from ${source}`);
        options = Object.assign(options || defaultOptions, forcedOptions);
        exifr.parse(response.Body, options)
          .then(exif => resolve(exif))
          .catch(err => reject(err));
      }
    })
  });
}

const getS3Key = (uri) => {
  return uri.path.replace(/^\/+/, "");
};

module.exports = { extractExif };
