const AWS = require("aws-sdk");
const FileType = require("file-type");
const path = require("path");

AWS.config.update({ httpOptions: { timeout: 600000 } });

const handler = async (event, _context, _callback) => {
  return await extractMimeType(event);
};

const extractMimeType = async (event) => {
  try {
    const s3 = new AWS.S3();

    const s3Stream = s3.getObject({
      Bucket: event.bucket,
      Key: event.key,
    }).createReadStream();

    // response: {"ext":"jpg","mime":"image/jpeg"}
    const fileType = await FileType.fromStream(s3Stream) || fallback(event);
    if (fileType) {
      console.log('identified file as', JSON.stringify(fileType));
      return { ...fileType, verified: true };  
    }
    return undefined;
  } catch (e) {
    console.error("Error extracting mime-type");
    return Promise.reject(e);
  }
};

const fallback = (event) => {
  const ext = path.extname(event.key).replace(/^\./, "");
  const mime = event.fallback;

  if (mime === undefined) 
    return { ext, mime: "application/octet-stream", verified: false }

  if (mime && (! mime.match(/xml$/)) && FileType.mimeTypes.has(mime)) {
    console.warn(`${path.basename(event.key)} attempting to fall back to ${mime} but magic number doesn't match.`);
    return undefined;
  }

  return {
    ext: path.extname(event.key).replace(/^\./, ""),
    mime: mime,
    verified: false
  }
}

module.exports = { handler };
