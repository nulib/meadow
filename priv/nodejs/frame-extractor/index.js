const AWS = require("aws-sdk");
const URI = require("uri-js");
const fs = require("fs");
const tempy = require("tempy");
const { spawnSync } = require("child_process");
const s3 = new AWS.S3();

AWS.config.update({ httpOptions: { timeout: 600000 } });

const dest_bucket = "meadow-s-streaming";

const handler = async (event, _context, _callback) => {
  return await extractFrame(event.bucket, event.key, event.offset);
};

const extractFrame = async (bucket, key, offset) => {
  console.log(
    `Extracting frame at offset ${offset} from s3://${bucket}/${key}`
  );

  const source = `s3://${bucket}/${key}`;
  const dest = `s3://${dest_bucket}/test-ffmpeg/test.jpg`;
  const dir = tempy.directory();

  try {
    const inputFile = await makeInputFile(source);
    const cmd = "/opt/bin/ffmpeg";
    const frameNumber = offset === "0" ? "00" : offset - 1;
    const frameNumberPadded = frameNumber.toString().padStart(2, "0");
    const vfArgs = `select=eq(n\\,${frameNumberPadded})`;

    const args = [
      "-i",
      inputFile,
      "-vf",
      '"' + vfArgs + '"',
      "-vframes",
      "1",
      `${dir}/out.jpg`,
    ];

    // proc = spawn(cmd, args, { shell: true });

    // proc.stdout.on("data", function (data) {
    //   console.log(data);
    // });

    // proc.stderr.setEncoding("utf8");
    // proc.stderr.on("data", function (data) {
    //   console.log(data);
    // });

    // proc.on("close", function () {
    //   console.log("finished");
    // });

    await runCommand(cmd, args);

    const data = fs.readFileSync(`${dir}/out.jpg`);

    uploadToS3(data, dest)
      .then((result) => console.log(result))
      .catch((err) => console.log(err));
    return Promise.resolve(dest);
  } finally {
    console.info(`Deleting ${dir}`);
    fs.rmdir(dir, { recursive: true }, (err) => {
      if (err) {
        throw err;
      }
    });
  }
};

const runCommand = (cmd, args) =>
  new Promise((resolve, reject) => {
    const command = spawnSync(cmd, args, { shell: true });
    command.on("data", (data) => {
      console.log(data);
    });
    command.on("close", () => resolve());
    command.on("error", (error) => {
      console.error(error);
      reject(error);
    });
  });

const makeInputFile = async (location) => {
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

const uploadToS3 = (data, location) => {
  let uri = URI.parse(location);
  return new Promise((resolve, reject) => {
    s3.upload(
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

const getS3Key = (uri) => {
  return uri.path.replace(/^\/+/, "");
};

module.exports = { handler };
