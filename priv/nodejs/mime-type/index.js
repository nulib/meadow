const AWS = require("aws-sdk");
const FileType = require("file-type");
const { makeTokenizer } = require("@tokenizer/s3");

const handler = async (event, context, _callback) => {
  context.callbackWaitsForEmptyEventLoop = false;
  return await extractMimeType(event.bucket, event.key);
};

const extractMimeType = async (bucket, key) => {
  try {
    const s3 = new AWS.S3();

    const s3Tokenizer = await makeTokenizer(s3, {
      Bucket: bucket,
      Key: key,
    });

    // response: {"ext":"jpg","mime":"image/jpeg"}
    const fileType = await FileType.fromTokenizer(s3Tokenizer);
    console.log(JSON.stringify(fileType));
    return fileType;
  } catch (e) {
    console.error("Error extracting mime-type");
    return Promise.reject(e);
  }
};

module.exports = { handler };
