const AWS = require("aws-sdk");
const FileType = require("file-type");
const MimeTypes = require("mime-types");
const { makeTokenizer } = require("@tokenizer/s3");
const path = require("path");

MimeTypes.types['md5'] = 'text/plain';
MimeTypes.types['framemd5'] = 'text/plain';

AWS.config.update({ httpOptions: { timeout: 600000 } });

const handler = async (event, _context, _callback) => {
  return await extractMimeType(event);
};

const extractMimeType = async (event) => {
  try {
    const s3 = new AWS.S3();

    const s3Tokenizer = await makeTokenizer(s3, {
      Bucket: event.bucket,
      Key: event.key,
    });

    // response: {"ext":"jpg","mime":"image/jpeg"}
    const fileType =
      (await FileType.fromTokenizer(s3Tokenizer)) || (await lookupMimeType(event));
    console.log(JSON.stringify(fileType));
    return fileType;
  } catch (e) {
    console.error("Error extracting mime-type");
    return Promise.reject(e);
  }
};

const lookupMimeType = async (event) => {
  console.warn(
    "Failed to extract MIME type from content. Falling back to file extension."
  );
  const key = event.key;
  const ext = path.extname(key).replace(/^\./, "");
  let mime = MimeTypes.lookup(key);
  if (mime && (! mime.match(/xml$/)) && FileType.mimeTypes.has(mime)) {
    console.warn(
      `${path.basename(
        key
      )} appears to be ${mime} but magic number doesn't match.`
    );
    return undefined;
  } else if (mime) {
    return { ext, mime };
  } else {
    console.warn(`Cannot determine MIME type of ${path.basename(key)}.`);
    return "null";
  }
};

module.exports = { handler };
