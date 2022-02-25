const AWS = require("aws-sdk");
const FileType = require("file-type");
const MimeTypes = require("mime-types");
const { makeTokenizer } = require("@tokenizer/s3");
const path = require("path");
const { XMLValidator } = require("fast-xml-parser");

if (process.env.LOCALSTACK_HOSTNAME) {
  AWS.config.update({
    endpoint: `http://${process.env.LOCALSTACK_HOSTNAME}:4566/`,
    s3ForcePathStyle: true
  });
}

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
  const mime = MimeTypes.lookup(event.key);
  if (FileType.mimeTypes.has(mime)) {
    if (await validateKnownType(mime, event)) {
      return { ext, mime }
    } else {
      return undefined;
    }
  } else if (mime) {
    return { ext, mime };
  } else {
    console.warn(`Cannot determine MIME type of ${path.basename(key)}.`);
    return "null";
  }
};

const validateKnownType = async (mimeType, event) => {
  const filename = path.basename(event.key);

  if (thinksItsXml(mimeType)) {
    const result = await validateXml(event);
    if (! result) {
      console.warn(`${filename} appears to be ${mimeType} but is not valid XML`);
    }
    return result;
  } else {
    console.warn(
      `${filename} appears to be ${mimeType} but magic number doesn't match.`
    );
    return undefined;  
  }
};

const thinksItsXml = (mimeType) => !!mimeType.match(/[/+]xml$/);

const validateXml = async (event) => {
  console.warn(`Confirming ${event.key} is well-formed XML`);
  const s3 = new AWS.S3();
  const response = await s3.getObject({Bucket: event.bucket, Key: event.key}).promise();
  const xml = response.Body.toString();
  const result = XMLValidator.validate(response.Body.toString());
  if (result.err) {
    console.warn(`${result.err.code}: ${result.err.msg}`);
    return false;
  } else {
    return true;
  }
};

module.exports = { handler };
