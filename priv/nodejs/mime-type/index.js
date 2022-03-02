const AWS = require("aws-sdk");
const FileType = require("file-type");
const MimeTypes = require("mime-types");
const { makeTokenizer } = require("@tokenizer/s3");
const path = require("path");

AWS.config.update({ httpOptions: { timeout: 600000 } });

const handler = async (event, _context, _callback) => {
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
    const fileType =
      (await FileType.fromTokenizer(s3Tokenizer)) || lookupMimeType(key);
    console.log(JSON.stringify(fileType));
    return fileType;
  } catch (e) {
    console.error("Error extracting mime-type");
    return Promise.reject(e);
  }
};

const lookupMimeType = (key) => {
  console.warn(
    "Failed to extract MIME type from content. Falling back to file extension."
  );
  const mimeType = MimeTypes.lookup(key);
  if (FileType.mimeTypes.has(mimeType)) {
    console.warn(
      `${path.basename(
        key
      )} appears to be ${mimeType} but magic number doesn't match.`
    );
    return undefined;
  } else if (mimeType) {
    return { ext: path.extname(key).replace(/^\./, ""), mime: mimeType };
  } else {
    console.warn(`Cannot determine MIME type of ${path.basename(key)}.`);
    return "null";
  }
};

module.exports = { handler };
