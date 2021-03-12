const AWS = require("aws-sdk");
const exifr = require("exifr");
const URI = require("uri-js");
const s3 = new AWS.S3();

AWS.config.update({httpOptions: {timeout: 600000}});

const chunkReader = (input, offset, length) => {
  return new Promise((resolve, _reject) => {
    let params = {...input};

    if (typeof offset === 'number') {
      let end = length ? offset + length - 1 : undefined;
      params.Range = `bytes=${[offset, end].join('-')}`;
    }

    s3.getObject(params, (err, data) => {
      if (err) {
        console.error(err);
        resolve(undefined);
      } else {
        resolve(data.Body);
      }
    });
  });
}

const extractExif = (source, options) => {
  return new Promise((resolve, reject) => {
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
      externalReader: chunkReader
    };
    
    const uri = URI.parse(source);
    const s3Location = { 
      Bucket: uri.host, 
      Key: uri.path.replace(/^\/+/, "")
    };

    options = Object.assign(options || defaultOptions, forcedOptions);
    exifr.parse(s3Location, options)
      .then(exif => resolve(exif))
      .catch(err => reject(err));
  });
}

module.exports = { extractExif };
