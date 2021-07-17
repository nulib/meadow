const AWS = require("aws-sdk");
const s3 = new AWS.S3();
const ffmpeg = require('fluent-ffmpeg');
const stream = require('stream');

const fs = require("fs");

AWS.config.update({ httpOptions: { timeout: 600000 } });

const handler = async (event, _context, _callback) => {
  return await extractFrame(
    event.source_bucket,
    event.dest_bucket,
    event.key,
    event.offset
  );
};

const extractFrame = async () => {
  const sourceBucket = "test-streaming";
  const destBucket = "test-streaming";
  const key =
    "6298d09f04833eb737504941812b0442e6253a4e286e79db3b11e16f9b39c604-1080_00001.ts";
  const offset = "5";

  // let readStream = s3
  //   .getObject({ Bucket: sourceBucket, Key: key })
  //   .createReadStream();

  let readStream = fs.createReadStream("/Users/brendan/test.ts");
  let writeStream = fs.createWriteStream("/Users/brendan/frame.jpg");

  let ffmpegProcess = new ffmpeg(readStream).outputOptions(["-vf select='eq(n\,02)'", "-vframes 1",]).toFormat("image2");

  ffmpegProcess.pipe(writeStream, { end: true });

  // ffmpegProcess
  //   .on("error", (err, stdout, stderr) => {})
  //   .on("end", () => {
  //     console.info("FINISHED");
  //   })
  //   .pipe(writeStream, {end: true });
    // .pipe(() => {
    //   let passThrough = new stream.PassThrough();

    //   s3.upload(
    //     { Bucket: destBucket, Key: "frame.jpg", Body: passThrough },
    //     (err, data) => {
    //       if (err) {
    //         return console.error(err);
    //       }
    //       console.info("UPLOADED");
    //     }
    //   );
    // });
};

module.exports = { handler };
