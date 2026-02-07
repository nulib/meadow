const { S3Client, GetObjectCommand } = require("@aws-sdk/client-s3");
const URI = require("uri-js");
const fs = require("fs");
const path = require("path");
const tmp = require("tmp-promise");
const { spawn } = require("child_process");

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
  "YResolution"
];

const exifToolPath = process.env.EXIFTOOL || "exiftool";
const exifToolParams = ["-fast", "-j", "-d", "%Y-%m-%dT%H:%M:%S%z"];

const version = async () => {
  const exifTool = spawn(exifToolPath, ["-ver"], {
    stdio: ["ignore", "pipe", process.stderr]
  });
  return await readOutput(exifTool);
};

const download = (source) => {
  return new Promise((resolve, reject) => {
    const uri = URI.parse(source);

    const s3Location = {
      Bucket: uri.host,
      Key: uri.path.replace(/^\/+/, "")
    };

    tmp.file({ template: "/tmp/exif-XXXXXX" }).then((outputFile) => {
      console.log(`Retrieving ${source} to ${outputFile.path}`);

      const s3Client = new S3Client(s3ClientOpts());
      s3Client
        .send(new GetObjectCommand(s3Location))
        .then(({ Body: inputStream }) => {
          inputStream
            .on("error", (error) => reject(error))
            .on("end", () => outputStream.close())
            .on("close", () => resolve(outputFile));

          const outputStream = fs
            .createWriteStream(null, { fd: outputFile.fd })
            .on("error", (error) => reject(error));

          inputStream.pipe(outputStream);
        })
        .catch((err) => reject(err));
    });
  });
};

const extract = async (source) => {
  const tempFile = await download(source);
  const args = exifToolParams
    .concat(includeTags.map((tag) => `-${tag}`))
    .concat([tempFile.path]);
  const exifTool = spawn(exifToolPath, args, {
    stdio: ["ignore", "pipe", process.stderr]
  });
  let output = await readOutput(exifTool);

  try {
    output = JSON.parse(output);
    if (Array.isArray(output) && output.length == 1) output = output[0];
  } catch (_err) {
    console.warn("Output is not JSON. Returning raw data.");
  }
  delete output.SourceFile;
  return output;
};

const readOutput = (child) => {
  return new Promise((resolve, reject) => {
    let buffer = "";
    let errored = false;
    child.on("error", (error) => {
      reject(error);
      errored = true;
    });
    child.on("exit", () => {
      if (!errored) resolve(buffer);
    });
    child.stdout
      .on("data", (data) => (buffer += data))
      .on("end", () => (buffer = buffer.trimEnd()));
  });
};

const s3ClientOpts = () => {
  const forcePathStyle = process.env.AWS_S3_FORCE_PATH_STYLE === "true";
  const endpoint = process.env.AWS_S3_ENDPOINT;
  return { endpoint, forcePathStyle, httpOptions: { timeout: 600000 } };
};

module.exports = { extract, version };
