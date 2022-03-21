const AWS = require("aws-sdk");
const URI = require("uri-js");
const s3 = new AWS.S3();
const { spawn } = require('child_process');

const includeTags = [
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
];

const exifToolPath = process.env.EXIFTOOL || 'exiftool';
const exifToolParams = ['-fast', '-j', '-d', '%Y-%m-%dT%H:%M:%S%z'];

AWS.config.update({httpOptions: {timeout: 600000}});

const version = async () => {
  const exifTool = spawn(exifToolPath, ['-ver'], {stdio: ['ignore', 'pipe', process.stderr]});
  return await readOutput(exifTool);
};

const extract = async (source) => {
  console.log(`Retrieving ${source}`);

  const uri = URI.parse(source);
  const s3Location = { 
    Bucket: uri.host, 
    Key: uri.path.replace(/^\/+/, "")
  };

  const args = exifToolParams.concat(includeTags.map((tag) => `-${tag}`)).concat(['-']);
  const inputStream = s3.getObject(s3Location).createReadStream();
  const exifTool = spawn(exifToolPath, args, {stdio: ['pipe', 'pipe', process.stderr]});
  inputStream.pipe(exifTool.stdin).on('error', (_error) => undefined);
  let output = await readOutput(exifTool);

  try {
    output = JSON.parse(output);
    if (Array.isArray(output) && output.length == 1) output = output[0];
  } catch (_err) {
    console.warn("Output is not JSON. Returning raw data.");
  }
  return output;
};

const readOutput = (child) => {
  return new Promise((resolve, reject) => {
    let buffer = '';
    child.on('error', (error) => reject(error));
    child.stdout
      .on('data', (data) => buffer += data)
      .on('end', () => buffer = buffer.trimEnd())
      .on('close', () => resolve(buffer));
  });
};

module.exports = { extract, version };
