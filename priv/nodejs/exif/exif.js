const exifr = require("exifr");
const cacheWorkingCopy = require('./working-copy');
const fs = require('fs');

const extractExif = async (source, options) => {
  const inputFile = await cacheWorkingCopy(source);
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
    fs.unlinkSync(inputFile);
  }
};

module.exports = { extractExif };
