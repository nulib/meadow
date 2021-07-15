const AWS = require("aws-sdk");
const URI = require("uri-js");
const fs = require("fs");
const tempy = require("tempy");
const spawn = require("child_process").spawn;
const { Buffer } = require("buffer");

AWS.config.update({ httpOptions: { timeout: 600000 } });

const handler = async (event, _context, _callback) => {
  return await extractFrame(event.source_bucket, event.dest_bucket, event.key, event.offset);
};

const extractFrame = async (sourceBucket, destBucket, key, offset) => {
  console.log(
    `Extracting frame at offset ${offset} from s3://${sourceBucket}/${key}`
  );

  const source = `s3://${sourceBucket}/${key}`;
  const dest = `s3://${destBucket}/test-ffmpeg/test.jpg`;
  const dir = tempy.directory();

  console.info(`DIRECTORY: ${dir}`);

  try {
    const inputFile = await makeInputFile(source);
    // const cmd = "/opt/bin/ffmpeg";
    const cmd = "/usr/local/bin/ffmpeg";
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

    await runCommand(cmd, args);


    return new Promise((resolve, reject) => {
      console.log('inside uploadToS3 function');
      fs.readFile(`${dir}/out.jpg`, function (err, data) {
          if (err) {
              reject(err);
              return;
          }

          const base64data = Buffer.from(data).toString('base64');
          const s3 = new AWS.S3();
          s3.putObject({
              Bucket: destBucket,
              Key: 'test.jpg',
              Body: base64data
          }, function (resp) {
              console.log('Done');
              resolve();
          });
      });
  });
  } finally {
    console.info(`Deleting ${dir}`);
    // fs.rmdir(dir, { recursive: true }, (err) => {
    //   if (err) {
    //     throw err;
    //   }
    // });
  }
};

const runCommand = (cmd, args) =>
  new Promise((resolve, reject) => {
    const command = spawn(cmd, args, { shell: true });
    command.on("data", (data) => {
      console.info(data);
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
